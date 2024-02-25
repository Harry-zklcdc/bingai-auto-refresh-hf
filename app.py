from flask import Flask, redirect

app = Flask(__name__)

@app.route('/<path:subpath>')
def subpath(subpath):
    return redirect('https://dongsiqie.me', code=302)

@app.route('/')
def index():
    return redirect('https://dongsiqie.me', code=302)

if __name__ == '__main__':
    app.run()
