# The test.py file is a unit test script for a Flask application. 

# It uses the unittest framework to test various routes in the application, 
# ensuring they return the expected status codes and contain the correct content.

# Several test methods are defined to check the functionality of different routes in the application:
# Test Methods:
# test_index: Tests the root route (/) to ensure it returns a 200 status code and contains the text "Tiger Home Page".
# test_index_html: Tests the /index.html route for the same conditions as the root route.
# test_symbol: Tests the /symbol.html route to ensure it returns a 200 status code and contains the text "Tiger As Symbol".
# test_myth: Tests the /myth.html route to ensure it returns a 200 status code and contains the text "Tiger in Myth and Legend".


import unittest
from routes import app  # Replace 'your_flask_app' with the name of your Python file without the .py extension

class FlaskAppTests(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_index(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Home page.', response.data)

    def test_index_html(self):
        response = self.app.get('/index.html')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Home page.', response.data)

    def test_symbol(self):
        response = self.app.get('/symbol.html')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Tiger As Symbol', response.data)

    def test_myth(self):
        response = self.app.get('/myth.html')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Tiger in Myth and Legend', response.data)

if __name__ == '__main__':
    unittest.main()