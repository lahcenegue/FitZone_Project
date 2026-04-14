'use strict';

/* ====================================================================
   LIGHTBOX ENGINE
   ==================================================================== */
window.openLightbox = function(imageSrc) {
    const modal = document.getElementById("lightboxModal");
    const img = document.getElementById("lightboxImg");
    if(modal && img) {
        img.src = imageSrc;
        modal.style.display = "flex";
    }
};

window.closeLightbox = function() {
    const modal = document.getElementById("lightboxModal");
    if(modal) modal.style.display = "none";
};

document.addEventListener('keydown', function(event) {
    if (event.key === "Escape") closeLightbox();
});

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
            <div style="text-align:center; padding: 32px; background: var(--color-bg); border: 1px dashed var(--color-border); border-radius: var(--radius-md); color: var(--color-text-muted); font-size: 15px; font-weight: bold;">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" style="margin-bottom: 12px; opacity: 0.5;"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg><br>
                No working hours specified.
            </div>`;
        return;
    }

    const daysMapping = {
        '0': 'Sun', '1': 'Mon', '2': 'Tue', '3': 'Wed', 
        '4': 'Thu', '5': 'Fri', '6': 'Sat'
    };

    const sortedPeriods = [...schedule].sort((a, b) => Math.min(...a.days) - Math.min(...b.days));
    const branchGender = targetGenderNode ? targetGenderNode.textContent.trim().toLowerCase() : 'mixed';
    const isMixed = branchGender === 'mixed' || branchGender === 'both';

    let html = '';

    function buildBox(periods, title, themeClass) {
        if(periods.length === 0) return '';
        
        let boxHtml = `<div class="split-col ${themeClass}">`;
        
        if (title) {
            let icon = '';
            if(themeClass === 'male-col') icon = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="10" cy="14" r="5"/><line x1="13.5" y1="10.5" x2="21" y2="3"/><polyline points="16 3 21 3 21 8"/></svg>';
            if(themeClass === 'female-col') icon = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="9" r="5"/><line x1="12" y1="14" x2="12" y2="22"/><line x1="9" y1="19" x2="15" y2="19"/></svg>';
            if(themeClass === 'both-col') icon = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>';
            
            boxHtml += `<h4 class="col-header">${icon} ${title}</h4>`;
        }

        boxHtml += `<div style="display: flex; flex-direction: column; gap: 12px;">`;
        periods.forEach(p => {
            const daysText = p.days.map(d => daysMapping[d] || d).join(', ');
            boxHtml += `
                <div class="period-card">
                    <div style="display:flex; flex-direction:column; gap:4px;">
                        <span class="period-days-text">${daysText}</span>
                        <span class="time-text">
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
        html += buildBox(sortedPeriods, '', 'none', false);
    }

    container.innerHTML = html;
});