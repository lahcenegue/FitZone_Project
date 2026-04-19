'use strict';

document.addEventListener("DOMContentLoaded", function() {

    // --- 1. Dashboard Modal Control ---
    const withdrawModal = document.getElementById('withdrawModal');
    const bankModal = document.getElementById('bankModal');

    window.openWithdraw = () => withdrawModal?.classList.add('show');
    window.closeWithdraw = () => withdrawModal?.classList.remove('show');
    window.openBank = () => bankModal?.classList.add('show');
    window.closeBank = () => bankModal?.classList.remove('show');

    // --- 2. Chart.js Theme Engine ---
    const style = getComputedStyle(document.documentElement);
    const colorPrimary = style.getPropertyValue('--color-primary').trim() || '#6366F1';
    const colorSuccess = style.getPropertyValue('--color-success').trim() || '#10B981';
    const colorPurple = style.getPropertyValue('--dash-color-4').trim() || '#8B5CF6';
    const colorBorder = style.getPropertyValue('--color-border').trim() || '#E2E8F0';
    const colorTextMuted = style.getPropertyValue('--color-text-muted').trim() || '#94A3B8';

    // Global Chart Config
    Chart.defaults.color = colorTextMuted;
    Chart.defaults.font.family = "'Inter', 'Tajawal', sans-serif";

    function getJSONData(id) {
        const el = document.getElementById(id);
        if (!el) return [];
        try { return JSON.parse(el.textContent); } 
        catch(e) { return []; }
    }

    // --- Line Chart: Monthly Revenue ---
    const ctxLine = document.getElementById('revenueTrendChart');
    if (ctxLine) {
        const labels = getJSONData('js_chart_labels');
        const data = getJSONData('js_chart_data');

        new Chart(ctxLine, {
            type: 'line',
            data: {
                labels: labels.length ? labels : ['-'],
                datasets: [{
                    label: 'Revenue (SAR)',
                    data: data.length ? data : [0],
                    borderColor: colorPrimary,
                    backgroundColor: 'rgba(99, 102, 241, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    pointBackgroundColor: '#fff',
                    pointBorderColor: colorPrimary,
                    pointRadius: 4,
                    pointHoverRadius: 6
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false } },
                scales: {
                    x: { grid: { display: false } },
                    y: { grid: { color: colorBorder, borderDash: [5, 5] }, beginAtZero: true }
                }
            }
        });
    }

    // --- Horizontal Bar Chart: Branch Performance ---
    const ctxBar = document.getElementById('performanceBarChart');
    if (ctxBar) {
        const labels = getJSONData('js_bar_labels');
        const data = getJSONData('js_bar_data');

        new Chart(ctxBar, {
            type: 'bar',
            data: {
                labels: labels.length ? labels : ['-'],
                datasets: [{
                    data: data.length ? data : [0],
                    backgroundColor: colorPurple,
                    borderRadius: 6,
                    barThickness: 20
                }]
            },
            options: {
                responsive: true, maintainAspectRatio: false,
                indexAxis: 'y', // Makes it horizontal
                plugins: { legend: { display: false } },
                scales: {
                    x: { display: false, beginAtZero: true },
                    y: { grid: { display: false }, ticks: { font: { weight: 'bold' } } }
                }
            }
        });
    }
});