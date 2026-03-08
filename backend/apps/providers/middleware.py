from django.utils import translation

class EnglishOnlyAPIMiddleware:
    """
    Forces all API responses to be in English.
    Web portal remains in the user's preferred language.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        is_api_request = request.path.startswith('/api/')
        
        if is_api_request:
            # Force English for API routes
            translation.activate('en')
        
        response = self.get_response(request)
        
        if is_api_request:
            # Deactivate so it doesn't affect other web pages
            translation.deactivate()
            
        return response