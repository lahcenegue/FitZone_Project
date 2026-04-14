'use strict';

/**
 * Auto-submit the upload form when files are selected
 */
window.handleFileSelect = function(inputElement) {
    if (inputElement.files && inputElement.files.length > 0) {
        document.getElementById('uploadForm').submit();
    }
};