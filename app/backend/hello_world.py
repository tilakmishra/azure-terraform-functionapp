import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="hello")
def hello(req: func.HttpRequest) -> func.HttpResponse:
    """Simple Hello World endpoint.
    - Auth: Anonymous
    - Usage:
      GET /api/hello
      GET /api/hello?name=Tilak
      POST /api/hello {"name": "Tilak"}
    """
    name = req.params.get("name")
    if not name:
        try:
            data = req.get_json()
            name = data.get("name")
        except ValueError:
            name = None

    message = f"Hello, {name}!" if name else "Hello, world!"
    return func.HttpResponse(message, status_code=200)
