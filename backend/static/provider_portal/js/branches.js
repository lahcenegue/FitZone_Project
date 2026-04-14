'use strict';

/**
 * Handle quick toggles for branch attributes (Visibility, Emergency Close)
 * Sends an AJAX request to the server and updates the UI dynamically.
 */
window.handleBranchToggle = async function(checkbox, branchId, fieldName, confirmMsg) {
    if (!confirm(confirmMsg)) {
        checkbox.checked = !checkbox.checked; // Revert visually
        return;
    }

    const url = `/portal/gym/branches/${branchId}/quick-toggle/`;
    const data = { field: fieldName };

    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': getCsrfToken() // From global.js
            },
            body: JSON.stringify(data)
        });

        const result = await response.json();

        if (result.status === 'success') {
            if (typeof showAlert === 'function') {
                showAlert(result.message, 'success', 'alert-container');
            }

            // --- UI Dynamic Badge Update Logic ---
            const card = document.getElementById(`branch-${branchId}`);
            if (card) {
                const badge = card.querySelector('.b-badge');
                if (badge) {
                    // Check the current state of both checkboxes in this specific card
                    const isActive = card.querySelector('input[onchange*="is_active"]').checked;
                    const isEmergency = card.querySelector('input[onchange*="is_temporarily_closed"]').checked;

                    // Update badge class and text dynamically based on the priority (Emergency > Active > Hidden)
                    if (isEmergency) {
                        badge.className = 'b-badge closed';
                        badge.textContent = badge.getAttribute('data-closed') || 'Emergency Close';
                    } else if (isActive) {
                        badge.className = 'b-badge active';
                        badge.textContent = badge.getAttribute('data-active') || 'Active';
                    } else {
                        badge.className = 'b-badge';
                        badge.textContent = badge.getAttribute('data-hidden') || 'Hidden';
                    }
                }
            }
            
        } else {
            throw new Error(result.message || 'Server error occurred.');
        }
    } catch (error) {
        console.error('Toggle Error:', error);
        if (typeof showAlert === 'function') {
            showAlert(error.message, 'error', 'alert-container');
        } else {
            alert(error.message);
        }
        checkbox.checked = !checkbox.checked; // Revert on failure
    }
};