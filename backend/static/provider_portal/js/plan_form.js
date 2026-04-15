'use strict';

document.addEventListener("DOMContentLoaded", function() {

    /* ====================================================================
       1. FLOATING LABELS INIT
       ==================================================================== */
    const floatContainers = document.querySelectorAll('.float-group');
    floatContainers.forEach(group => {
        const input = group.querySelector('input:not([type="hidden"]):not([type="checkbox"]), select:not([multiple]), textarea');
        if (input) {
            input.classList.add('float-input');
            if (!input.getAttribute('placeholder')) {
                input.setAttribute('placeholder', ' ');
            }
        }
    });

    /* ====================================================================
       2. DYNAMIC FEATURES LOGIC (Based on Selected Branches)
       ==================================================================== */
    const branchMapNode = document.getElementById('branchFeaturesMap');
    let branchMap = {};
    if (branchMapNode) {
        try {
            branchMap = JSON.parse(branchMapNode.textContent);
        } catch (e) {
            console.error("Failed to parse branch map JSON");
        }
    }

    const mask = document.getElementById('featuresMask');
    const amenitiesSelect = document.querySelector('select[name="amenities"]');
    const sportsSelect = document.querySelector('select[name="sports"]');

    function refreshSelect2(selectElement) {
        if (typeof jQuery !== 'undefined' && $.fn.select2 && selectElement) {
            if ($(selectElement).hasClass("select2-hidden-accessible")) {
                $(selectElement).select2('destroy');
            }
            $(selectElement).select2({ width: '100%', placeholder: ' ', allowClear: true });
        }
    }

    function updateAvailableFeatures() {
        const checkedBoxes = document.querySelectorAll('#dropdownContent input[type="checkbox"]:checked');
        
        if (checkedBoxes.length === 0) {
            if (mask) mask.classList.remove('hidden');
            // Clear selections if no branch is selected
            if (typeof jQuery !== 'undefined' && $.fn.select2) {
                if (amenitiesSelect) $(amenitiesSelect).val(null).trigger('change');
                if (sportsSelect) $(sportsSelect).val(null).trigger('change');
            }
            return;
        }

        if (mask) mask.classList.add('hidden');

        // Build a Set of all available features across selected branches
        let allowedAmenities = new Set();
        let allowedSports = new Set();

        checkedBoxes.forEach(cb => {
            const branchId = cb.value;
            if (branchMap[branchId]) {
                branchMap[branchId].amenities.forEach(id => allowedAmenities.add(id.toString()));
                branchMap[branchId].sports.forEach(id => allowedSports.add(id.toString()));
            }
        });

        // Filter Amenities Options
        if (amenitiesSelect) {
            Array.from(amenitiesSelect.options).forEach(opt => {
                if (!opt.value) return; // Skip placeholder
                if (allowedAmenities.has(opt.value)) {
                    opt.disabled = false;
                } else {
                    opt.disabled = true;
                    opt.selected = false; // Unselect if it was selected previously
                }
            });
            refreshSelect2(amenitiesSelect);
        }

        // Filter Sports Options
        if (sportsSelect) {
            Array.from(sportsSelect.options).forEach(opt => {
                if (!opt.value) return; // Skip placeholder
                if (allowedSports.has(opt.value)) {
                    opt.disabled = false;
                } else {
                    opt.disabled = true;
                    opt.selected = false;
                }
            });
            refreshSelect2(sportsSelect);
        }
    }

    /* ====================================================================
       3. CUSTOM BRANCH DROPDOWN LOGIC
       ==================================================================== */
    const dropdownHeader = document.getElementById('dropdownHeader');
    const dropdownContent = document.getElementById('dropdownContent');
    const dropdownTitle = document.getElementById('dropdownTitle');
    const branchesGroup = document.getElementById('branchesGroup');
    
    if (dropdownHeader && dropdownContent) {
        dropdownHeader.addEventListener('click', function(e) {
            dropdownHeader.classList.toggle('active');
            dropdownContent.classList.toggle('show');
            e.stopPropagation();
        });

        document.addEventListener('click', function(e) {
            if (!branchesGroup.contains(e.target)) {
                dropdownContent.classList.remove('show');
                dropdownHeader.classList.remove('active');
            }
        });
    }

    window.toggleCheckbox = function(rowElement, event) {
        if(event.target.tagName !== 'INPUT') {
            const checkbox = rowElement.querySelector('input[type="checkbox"]');
            checkbox.checked = !checkbox.checked;
            checkbox.dispatchEvent(new Event('change')); // Trigger features update
        }
        updateDropdownTitle();
    };

    function updateDropdownTitle() {
        const checkedBoxes = document.querySelectorAll('#dropdownContent input[type="checkbox"]:checked');
        if (checkedBoxes.length === 0) {
            dropdownTitle.textContent = dropdownTitle.getAttribute('data-default');
        } else if (checkedBoxes.length === 1) {
            dropdownTitle.textContent = checkedBoxes[0].nextElementSibling.textContent;
        } else {
            dropdownTitle.textContent = checkedBoxes.length + ' ' + dropdownTitle.getAttribute('data-multiple');
        }
    }

    const selectAllBtn = document.getElementById('selectAllBranches');
    if (selectAllBtn) {
        selectAllBtn.addEventListener('click', function(e) {
            e.stopPropagation();
            const checkboxes = dropdownContent.querySelectorAll('input[type="checkbox"]');
            const allChecked = Array.from(checkboxes).every(cb => cb.checked);
            checkboxes.forEach(cb => {
                cb.checked = !allChecked;
                cb.dispatchEvent(new Event('change')); // Trigger features update
            });
            this.textContent = allChecked ? this.getAttribute('data-select') : this.getAttribute('data-deselect');
            updateDropdownTitle();
        });
    }
    
    // Bind change event to all checkboxes to trigger updateAvailableFeatures
    const allCheckboxes = document.querySelectorAll('#dropdownContent input[type="checkbox"]');
    allCheckboxes.forEach(cb => {
        cb.addEventListener('change', updateAvailableFeatures);
    });

    if(dropdownTitle) updateDropdownTitle(); // Init on load

    /* ====================================================================
       4. SELECT2 INITIALIZATION
       ==================================================================== */
    refreshSelect2(amenitiesSelect);
    refreshSelect2(sportsSelect);
    
    // Initial evaluation of mask and available features
    updateAvailableFeatures();

    /* ====================================================================
       5. FORM VALIDATION
       ==================================================================== */
    const planForm = document.getElementById('planForm');
    if(planForm) {
        planForm.addEventListener('submit', function(e) {
            let hasError = false;
            
            const inputs = this.querySelectorAll('input[required], textarea[required]');
            inputs.forEach(el => {
                if(!el.value.trim()) {
                    el.style.borderColor = 'var(--color-error)';
                    hasError = true;
                } else {
                    el.style.borderColor = 'var(--color-border)';
                }
            });

            const branchCheckboxes = document.querySelectorAll('#dropdownContent input[type="checkbox"]');
            if (branchCheckboxes.length > 0) {
                const isChecked = Array.from(branchCheckboxes).some(cb => cb.checked);
                if (!isChecked) {
                    dropdownHeader.style.borderColor = 'var(--color-error)';
                    hasError = true;
                } else {
                    dropdownHeader.style.borderColor = 'var(--color-border)';
                }
            }

            if(hasError) {
                e.preventDefault();
                const errorMsg = planForm.getAttribute('data-error-msg');
                if (typeof showAlert === 'function') {
                    showAlert(errorMsg, 'error', 'alert-container');
                } else {
                    alert(errorMsg);
                }
            }
        });
    }
});