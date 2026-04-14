'use strict';

/* ==========================================================================
   CSV EXPORT UTILITY (WITH ARABIC UTF-8 BOM SUPPORT)
   ========================================================================== */
window.exportDataToCSV = function(tableId, filename) {
    const table = document.getElementById(tableId);
    if (!table) return;

    let csvArray = [];
    const rows = table.querySelectorAll("tr");
    
    for (let i = 0; i < rows.length; i++) {
        let rowData = [];
        const cols = rows[i].querySelectorAll("td, th");
        
        for (let j = 0; j < cols.length; j++) {
            let text = cols[j].innerText.replace(/(\r\n|\n|\r)/gm, " ").trim();
            text = text.replace(/"/g, '""');
            rowData.push('"' + text + '"');
        }
        csvArray.push(rowData.join(","));
    }
    
    const csvContent = "\uFEFF" + csvArray.join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    
    if (navigator.msSaveBlob) {
        navigator.msSaveBlob(blob, filename);
    } else {
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        link.style.display = "none";
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }
};

/* ==========================================================================
   CHART.JS CONFIGURATION & INITIALIZATION
   ========================================================================== */
document.addEventListener("DOMContentLoaded", function() {
    
    Chart.defaults.font.family = 'Inter, Tajawal, sans-serif';
    Chart.defaults.color = '#94A3B8';
    
    const colorPrimary = '#6366F1';
    const colorSuccess = '#10B981';
    const colorWarning = '#F59E0B';
    const colorPurple = '#8B5CF6';
    const colorSlate = '#CBD5E1';

    // Helper safely parse JSON injected via Django
    function getChartData(elementId) {
        const el = document.getElementById(elementId);
        return el ? JSON.parse(el.textContent) : [];
    }

    // 1. Attendance Trend (Smooth Area Chart)
    const ctxTrend = document.getElementById('trendChart');
    if (ctxTrend) {
        const labels = getChartData('js_trend_labels');
        const data = getChartData('js_trend_data');
        
        let gradient = ctxTrend.getContext('2d').createLinearGradient(0, 0, 0, 350);
        gradient.addColorStop(0, 'rgba(99, 102, 241, 0.4)');
        gradient.addColorStop(1, 'rgba(99, 102, 241, 0.0)');

        new Chart(ctxTrend, {
            type: 'line',
            data: {
                labels: labels.length ? labels : ['-'],
                datasets: [{
                    label: 'Check-ins',
                    data: data.length ? data : [0],
                    borderColor: colorPrimary,
                    backgroundColor: gradient,
                    borderWidth: 3,
                    pointBackgroundColor: '#ffffff',
                    pointBorderColor: colorPrimary,
                    pointBorderWidth: 2,
                    pointRadius: 4,
                    pointHoverRadius: 6,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true, 
                maintainAspectRatio: false,
                plugins: { 
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: '#0F172A', padding: 12,
                        titleFont: { size: 13 }, bodyFont: { size: 14, weight: 'bold' }
                    }
                },
                scales: {
                    x: { grid: { display: false, drawBorder: false } },
                    y: { grid: { color: 'rgba(0,0,0,0.04)', drawBorder: false, borderDash: [5, 5] }, beginAtZero: true, ticks: { precision: 0, padding: 10 } }
                }
            }
        });
    }

    // 2. Peak Hours Analysis (Bar Chart)
    const ctxPeak = document.getElementById('peakHoursChart');
    if (ctxPeak) {
        const labels = getChartData('js_peak_labels');
        const data = getChartData('js_peak_data');
        
        new Chart(ctxPeak, {
            type: 'bar',
            data: {
                labels: labels.length ? labels : ['-'],
                datasets: [{
                    label: 'Visits',
                    data: data.length ? data : [0],
                    backgroundColor: colorWarning,
                    borderRadius: 6,
                    barThickness: 'flex',
                    maxBarThickness: 32,
                    hoverBackgroundColor: '#D97706'
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
                plugins: { legend: { position: 'bottom', labels: { usePointStyle: true, padding: 24, font: { size: 13, family: 'Inter, Tajawal, sans-serif' } } } }
            }
        });
    }
});