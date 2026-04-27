'use strict';

/* ====================================================================
   SMART SCHEDULE RENDERER (Matches Form Output Exactly)
   ==================================================================== */
document.addEventListener("DOMContentLoaded", function() {
    const container = document.getElementById('scheduleRenderContainer');
    const jsonNode = document.getElementById('branch-schedule-data');
    const targetGenderNode = document.getElementById('branch-target-gender');
    
    if(!container || !jsonNode) return;

    let schedule = [];
    try {
        schedule = JSON.parse(jsonNode.textContent);
    } catch(e) {
        console.error("Error parsing schedule JSON", e);
    }

    if(!schedule || schedule.length === 0) {
        container.innerHTML = `
            <div style="text-align:center; padding:32px 16px; color:var(--color-error); border:1px dashed var(--color-error); border-radius:var(--radius-md); background: var(--color-error-light);">
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                <strong style="display:block; margin-top:8px; font-size:15px;">Working hours are missing!</strong>
                <span style="font-size:13px; margin-top:4px; display:block;">Please edit the branch to add operating hours. This is required for the app to function properly.</span>
            </div>
        `;
        return;
    }

    const dayOrder = { "Monday":1, "Tuesday":2, "Wednesday":3, "Thursday":4, "Friday":5, "Saturday":6, "Sunday":7 };
    
    let sortedPeriods = schedule.sort((a, b) => {
        const daysA = a.days.sort((d1, d2) => dayOrder[d1] - dayOrder[d2]);
        const daysB = b.days.sort((d1, d2) => dayOrder[d1] - dayOrder[d2]);
        return dayOrder[daysA[0]] - dayOrder[daysB[0]];
    });

    const targetGender = targetGenderNode ? targetGenderNode.textContent.trim().toLowerCase() : 'both';
    const isMixed = (targetGender === 'mixed' || targetGender === 'both');

    let html = '';

    function buildBox(periods, title, themeClass) {
        let boxHtml = `
            <div class="schedule-col ${themeClass}">
                <div class="col-header">${title}</div>
                <div class="col-body">
        `;
        periods.forEach(p => {
            boxHtml += `
                <div class="schedule-item" style="padding: 12px; background: var(--color-bg); border-radius: var(--radius-md); border: 1px solid var(--color-border); margin-bottom: 8px;">
                    <div class="schedule-days" style="font-weight: var(--font-weight-bold); margin-bottom: 4px;">${p.days.join(', ')}</div>
                    <div class="schedule-time" style="font-size: 13px; color: var(--color-text-secondary); display: flex; align-items: center; gap: 6px;">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                        ${p.start} - ${p.end}
                    </div>
                </div>
            `;
        });
        boxHtml += `</div></div>`;
        return boxHtml;
    }

    if(isMixed) {
        const malePeriods = sortedPeriods.filter(p => p.gender === 'male' || p.gender === 'm' || p.gender === 'men');
        const femalePeriods = sortedPeriods.filter(p => p.gender === 'female' || p.gender === 'f' || p.gender === 'women');
        const bothPeriods = sortedPeriods.filter(p => p.gender === 'both' || p.gender === 'mixed');

        if (bothPeriods.length > 0) {
            html += buildBox(bothPeriods, 'Mixed Schedule (Both Genders)', 'both-col');
        }

        if (malePeriods.length > 0 || femalePeriods.length > 0) {
            html += `<div class="schedule-split-layout" style="margin-top: 16px;">`;
            if (malePeriods.length > 0) html += buildBox(malePeriods, 'Men Schedule', 'male-col');
            if (femalePeriods.length > 0) html += buildBox(femalePeriods, 'Women Schedule', 'female-col');
            html += `</div>`;
        }
    } else {
        html += buildBox(sortedPeriods, 'Branch Schedule', 'both-col');
    }

    container.innerHTML = html;
});

/* ====================================================================
   LINK & UNLINK PLAN AJAX FUNCTIONALITY
   ==================================================================== */

function linkPlanToBranch(planId, planName, durationDays, price) {
    const branchId = window.location.pathname.split('/').filter(Boolean).pop(); 
    const url = `/portal/gym/branches/${branchId}/link-plan/`; 
    const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]')?.value || '';

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': csrfToken
        },
        body: JSON.stringify({ plan_id: planId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            const unlinkedCard = document.getElementById(`unlinked-plan-${planId}`);
            if (unlinkedCard) unlinkedCard.remove();

            const emptyState = document.getElementById('emptyPlansState');
            if (emptyState) emptyState.style.display = 'none';

            const linkedList = document.getElementById('linkedPlansList');
            if (linkedList) {
                const newCard = document.createElement('div');
                newCard.className = 'plan-card-mini';
                newCard.id = `linked-plan-${planId}`;
                newCard.innerHTML = `
                    <a href="/portal/gym/plans/${planId}/" class="plan-mini-info" style="text-decoration: none; flex: 1;">
                        <h4>${planName}</h4>
                        <p>${durationDays} Days</p>
                    </a>
                    <div class="plan-mini-price">
                        ${price}
                        <span style="display:inline-flex; width:16px;">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
                        </span>
                    </div>
                    <button type="button" class="btn-unlink-plan" onclick="unlinkPlanFromBranch(${planId}, '${planName.replace(/'/g, "\\'")}', ${durationDays}, ${price})" title="Unlink Plan">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                    </button>
                `;
                linkedList.appendChild(newCard);
            }

            document.getElementById('linkPlanModal').classList.remove('show');
            alert(data.message);
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error linking plan:', error);
        alert('A network error occurred.');
    });
}

function unlinkPlanFromBranch(planId, planName, durationDays, price) {
    if (!confirm('Are you sure you want to remove this plan from the branch?')) return;
    
    const branchId = window.location.pathname.split('/').filter(Boolean).pop(); 
    const url = `/portal/gym/branches/${branchId}/unlink-plan/`; 
    const csrfToken = document.querySelector('[name=csrfmiddlewaretoken]')?.value || '';

    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': csrfToken
        },
        body: JSON.stringify({ plan_id: planId })
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            const linkedCard = document.getElementById(`linked-plan-${planId}`);
            if (linkedCard) linkedCard.remove();

            const unlinkedList = document.querySelector('#linkPlanModal .plans-list');
            if (unlinkedList) {
                const newUnlinkedCard = document.createElement('div');
                newUnlinkedCard.className = 'plan-card-mini';
                newUnlinkedCard.style.borderColor = 'var(--color-border)';
                newUnlinkedCard.id = `unlinked-plan-${planId}`;
                newUnlinkedCard.innerHTML = `
                    <div class="plan-mini-info">
                        <h4>${planName}</h4>
                        <p>${durationDays} Days • ${price} SAR</p>
                    </div>
                    <button type="button" class="btn-action btn-outline" style="padding: 6px 12px; font-size: 12px;" onclick="linkPlanToBranch(${planId}, '${planName.replace(/'/g, "\\'")}', ${durationDays}, ${price})">
                        Link Plan
                    </button>
                `;
                
                const modalEmpty = unlinkedList.querySelector('div[style*="text-align:center"]');
                if (modalEmpty && !modalEmpty.classList.contains('plan-card-mini')) {
                    modalEmpty.remove();
                }
                unlinkedList.appendChild(newUnlinkedCard);
            }

            const linkedListContainer = document.getElementById('linkedPlansList');
            if (linkedListContainer && linkedListContainer.querySelectorAll('.plan-card-mini').length === 0) {
                linkedListContainer.innerHTML = `
                    <div id="emptyPlansState" style="text-align:center; padding:32px 16px; color:var(--color-text-muted); border:1px dashed var(--color-border); border-radius:var(--radius-md); display:flex; flex-direction:column; align-items:center; gap:8px;">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                        <span style="font-size:13px; font-weight:var(--font-weight-bold);">No active plans linked.</span>
                    </div>
                `;
            }

            alert(data.message);
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(error => {
        console.error('Error unlinking plan:', error);
        alert('A network error occurred.');
    });
}