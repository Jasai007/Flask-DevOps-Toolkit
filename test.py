import unittest
from routes import app  # Replace 'your_flask_app' with the name of your Python file without the .py extension

class FlaskAppTests(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_index(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Tiger Home Page', response.data)

    def test_index_html(self):
        response = self.app.get('/index.html')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Tiger Home Page', response.data)

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