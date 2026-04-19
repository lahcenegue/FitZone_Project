'use strict';

/**
 * FitZone Dashboard — Chart Engine
 * Renders all analytics charts with professional styling.
 * Reads CSS variables for theme-aware colors (light/dark mode).
 *
 * Canvas IDs (from dashboard.html):
 *   - revenueChart        ← js_revenue_labels / js_revenue_data
 *   - trendChart          ← js_trend_labels   / js_trend_data
 *   - peakHoursChart      ← js_peak_labels    / js_peak_data
 *   - demographicsChart   ← js_demo_labels    / js_demo_data
 */

document.addEventListener("DOMContentLoaded", function () {

    /* ──────────────────────────────────────────────
       Helpers
    ────────────────────────────────────────────── */
    const css = (prop) =>
        getComputedStyle(document.documentElement).getPropertyValue(prop).trim();

    // Theme-aware palette
    const colorPrimary     = css('--color-primary')       || '#6366F1';
    const colorSuccess     = css('--color-success')       || '#10B981';
    const colorWarning     = css('--color-warning')       || '#F59E0B';
    const colorError       = css('--color-error')         || '#EF4444';
    const colorPurple      = css('--color-purple')        || '#8B5CF6';
    const colorInfo        = css('--color-info')          || '#3B82F6';
    const colorBorder      = css('--color-border')        || '#E2E8F0';
    const colorTextMuted   = css('--color-text-muted')    || '#94A3B8';
    const colorTextPrimary = css('--color-text-primary')  || '#0F172A';
    const colorSurface     = css('--color-surface')       || '#FFFFFF';

    // Safely parse JSON data embedded by Django's json_script tag
    function getData(id) {
        const el = document.getElementById(id);
        if (!el) return [];
        try { return JSON.parse(el.textContent); }
        catch (e) { console.error(`Dashboard: failed to parse #${id}`, e); return []; }
    }

    // Shared chart defaults for a clean, professional look
    const sharedOptions = {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 800, easing: 'easeOutQuart' },
        plugins: {
            legend: { display: false },
            tooltip: {
                backgroundColor: colorSurface,
                titleColor: colorTextPrimary,
                bodyColor: colorTextPrimary,
                borderColor: colorBorder,
                borderWidth: 1,
                padding: 12,
                cornerRadius: 8,
                titleFont: { weight: 'bold', size: 13 },
                bodyFont: { size: 13 },
                displayColors: true,
                boxPadding: 6,
                usePointStyle: true,
            }
        }
    };

    const gridStyle = {
        color: 'rgba(0,0,0,0.04)',
        drawBorder: false,
        borderDash: [4, 4]
    };

    /* ──────────────────────────────────────────────
       1. Revenue Trend (Last 6 Months) — Area Line Chart
       Canvas: #revenueChart
       Data:   #js_revenue_labels, #js_revenue_data
    ────────────────────────────────────────────── */
    const ctxRevenue = document.getElementById('revenueChart');
    if (ctxRevenue) {
        const labels = getData('js_revenue_labels');
        const data   = getData('js_revenue_data');

        const gradient = ctxRevenue.getContext('2d').createLinearGradient(0, 0, 0, 350);
        gradient.addColorStop(0, 'rgba(16, 185, 129, 0.18)');
        gradient.addColorStop(1, 'rgba(16, 185, 129, 0.0)');

        new Chart(ctxRevenue, {
            type: 'line',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Revenue',
                    data: data,
                    borderColor: colorSuccess,
                    backgroundColor: gradient,
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    pointBackgroundColor: colorSurface,
                    pointBorderColor: colorSuccess,
                    pointBorderWidth: 2.5,
                    pointRadius: 5,
                    pointHoverRadius: 8,
                    pointHoverBackgroundColor: colorSuccess,
                    pointHoverBorderColor: colorSurface,
                    pointHoverBorderWidth: 3
                }]
            },
            options: {
                ...sharedOptions,
                interaction: { mode: 'index', intersect: false },
                scales: {
                    x: {
                        grid: { display: false, drawBorder: false },
                        ticks: { color: colorTextMuted, font: { size: 12, weight: '600' }, padding: 8 }
                    },
                    y: {
                        grid: gridStyle,
                        beginAtZero: true,
                        ticks: { color: colorTextMuted, font: { size: 12 }, padding: 8 }
                    }
                }
            }
        });
    }

    /* ──────────────────────────────────────────────
       2. Attendance Trend (Last 7 Days) — Line Chart
       Canvas: #trendChart
       Data:   #js_trend_labels, #js_trend_data
    ────────────────────────────────────────────── */
    const ctxTrend = document.getElementById('trendChart');
    if (ctxTrend) {
        const labels = getData('js_trend_labels');
        const data   = getData('js_trend_data');

        // Format date labels to short format (e.g., "Apr 17")
        const formattedLabels = labels.map(function(dateStr) {
            try {
                const d = new Date(dateStr + 'T00:00:00');
                return d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
            } catch(e) { return dateStr; }
        });

        const gradient = ctxTrend.getContext('2d').createLinearGradient(0, 0, 0, 350);
        gradient.addColorStop(0, 'rgba(99, 102, 241, 0.15)');
        gradient.addColorStop(1, 'rgba(99, 102, 241, 0.0)');

        new Chart(ctxTrend, {
            type: 'line',
            data: {
                labels: formattedLabels,
                datasets: [{
                    label: 'Check-ins',
                    data: data,
                    borderColor: colorPrimary,
                    backgroundColor: gradient,
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    pointBackgroundColor: colorSurface,
                    pointBorderColor: colorPrimary,
                    pointBorderWidth: 2.5,
                    pointRadius: 5,
                    pointHoverRadius: 8,
                    pointHoverBackgroundColor: colorPrimary,
                    pointHoverBorderColor: colorSurface,
                    pointHoverBorderWidth: 3
                }]
            },
            options: {
                ...sharedOptions,
                interaction: { mode: 'index', intersect: false },
                scales: {
                    x: {
                        grid: { display: false, drawBorder: false },
                        ticks: { color: colorTextMuted, font: { size: 12, weight: '600' }, padding: 8 }
                    },
                    y: {
                        grid: gridStyle,
                        beginAtZero: true,
                        ticks: { color: colorTextMuted, font: { size: 12 }, padding: 8, precision: 0 }
                    }
                }
            }
        });
    }

    /* ──────────────────────────────────────────────
       3. Peak Hours Analysis (30 Days) — Bar Chart
       Canvas: #peakHoursChart
       Data:   #js_peak_labels, #js_peak_data
    ────────────────────────────────────────────── */
    const ctxPeak = document.getElementById('peakHoursChart');
    if (ctxPeak) {
        const labels = getData('js_peak_labels');
        const data   = getData('js_peak_data');

        // Color bars by intensity — busier hours get a stronger color
        const maxVal = Math.max(...data, 1);
        const barColors = data.map(function(val) {
            const intensity = Math.max(0.2, val / maxVal);
            return `rgba(99, 102, 241, ${intensity})`;
        });

        new Chart(ctxPeak, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label: 'Check-ins',
                    data: data,
                    backgroundColor: barColors,
                    borderRadius: 6,
                    borderSkipped: false,
                    barPercentage: 0.7,
                    categoryPercentage: 0.8
                }]
            },
            options: {
                ...sharedOptions,
                scales: {
                    x: {
                        grid: { display: false, drawBorder: false },
                        ticks: {
                            color: colorTextMuted,
                            font: { size: 11, weight: '600' },
                            maxRotation: 0,
                            callback: function(value, index) {
                                return index % 2 === 0 ? this.getLabelForValue(value) : '';
                            }
                        }
                    },
                    y: {
                        grid: gridStyle,
                        beginAtZero: true,
                        ticks: { color: colorTextMuted, font: { size: 12 }, padding: 8, precision: 0 }
                    }
                }
            }
        });
    }

    /* ──────────────────────────────────────────────
       4. Demographics Distribution — Doughnut Chart
       Canvas: #demographicsChart
       Data:   #js_demo_labels, #js_demo_data
    ────────────────────────────────────────────── */
    const ctxDemo = document.getElementById('demographicsChart');
    if (ctxDemo) {
        const labels = getData('js_demo_labels');
        const data   = getData('js_demo_data');

        const hasData = data.some(function(v) { return v > 0; });

        new Chart(ctxDemo, {
            type: 'doughnut',
            data: {
                labels: hasData ? labels : ['No Data'],
                datasets: [{
                    data: hasData ? data : [1],
                    backgroundColor: hasData
                        ? [colorInfo, colorPurple, colorBorder]
                        : ['rgba(0,0,0,0.05)'],
                    borderWidth: 0,
                    hoverOffset: 8,
                    spacing: 2
                }]
            },
            options: {
                ...sharedOptions,
                cutout: '72%',
                plugins: {
                    ...sharedOptions.plugins,
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: {
                            usePointStyle: true,
                            pointStyle: 'circle',
                            padding: 20,
                            color: colorTextPrimary,
                            font: { size: 13, weight: '600' }
                        }
                    }
                }
            }
        });
    }

});