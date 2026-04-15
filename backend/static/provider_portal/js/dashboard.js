'use strict';

document.addEventListener("DOMContentLoaded", function() {

    const colorPrimary = getComputedStyle(document.documentElement).getPropertyValue('--color-primary').trim() || '#6366F1';
    const colorSuccess = getComputedStyle(document.documentElement).getPropertyValue('--color-success').trim() || '#10B981';
    const colorPurple = getComputedStyle(document.documentElement).getPropertyValue('--dash-color-4').trim() || '#8B5CF6';
    const colorSlate = getComputedStyle(document.documentElement).getPropertyValue('--color-border').trim() || '#E2E8F0';

    function getChartData(elementId) {
        const el = document.getElementById(elementId);
        if(!el) return [];
        try {
            return JSON.parse(el.textContent);
        } catch(e) {
            console.error(`Error parsing data from ${elementId}`, e);
            return [];
        }
    }

    // 1. Revenue Overview Chart
    const ctxRevenue = document.getElementById('revenueChart');
    if (ctxRevenue) {
        const labels = getChartData('js_revenue_labels');
        const data = getChartData('js_revenue_data');
        
        new Chart(ctxRevenue, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Revenue (SAR)',
                    data: data,
                    borderColor: colorPrimary,
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    pointBackgroundColor: '#fff',
                    pointBorderColor: colorPrimary,
                    pointBorderWidth: 2,
                    pointRadius: 4,
                    pointHoverRadius: 6
                }]
            },
            options: {
                responsive: true, 
                maintainAspectRatio: false,
                plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false } },
                scales: {
                    x: { grid: { display: false, drawBorder: false } },
                    y: { grid: { color: 'rgba(0,0,0,0.04)', drawBorder: false, borderDash: [5, 5] }, beginAtZero: true }
                }
            }
        });
    }

    // 2. Weekly Visits Activity
    const ctxVisits = document.getElementById('visitsChart');
    if (ctxVisits) {
        const labels = getChartData('js_visits_labels');
        const data = getChartData('js_visits_data');
        
        new Chart(ctxVisits, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Visits',
                    data: data,
                    backgroundColor: colorPurple,
                    borderRadius: 6,
                    barThickness: 12
                }]
            },
            options: {
                responsive: true, 
                maintainAspectRatio: false,
                plugins: { legend: { display: false } },
                scales: {
                    x: { grid: { display: false, drawBorder: false }, ticks: { maxRotation: 45, minRotation: 45 } },
                    y: { grid: { color: 'rgba(0,0,0,0.04)', drawBorder: false, borderDash: [5, 5] }, beginAtZero: true, ticks: { precision: 0 } }
                }
            }
        });
    }

    // 3. Demographics Distribution (Doughnut Chart)
    const ctxDemo = document.getElementById('demographicsChart');
    if (ctxDemo) {
        const labels = getChartData('js_demo_labels');
        const data = getChartData('js_demo_data');
        
        new Chart(ctxDemo, {
            type: 'doughnut',
            data: {
                labels: labels.length ? labels : ['No Data'],
                datasets: [{
                    data: data.length ? data : [1],
                    backgroundColor: [colorSuccess, colorPurple, colorSlate],
                    borderWidth: 0,
                    hoverOffset: 6
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false, cutout: '75%',
                plugins: { legend: { position: 'bottom', labels: { usePointStyle: true, padding: 24, font: { size: 13, family: 'inherit' } } } }
            }
        });
    }
});