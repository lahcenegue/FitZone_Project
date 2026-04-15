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
        container.innerHTML = `<div style="text-align:center; color:var(--color-text-muted); font-size:13px; font-style:italic;">No schedule configured.</div>`;
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
                <div class="schedule-item">
                    <div class="schedule-days">${p.days.join(', ')}</div>
                    <div class="schedule-time">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                        <span style="display:flex; align-items:center; gap:6px;">
                            ${p.start} 
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--color-border)" stroke-width="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg> 
                            ${p.end}
                        </span>
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