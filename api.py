from fastapi import FastAPI

import mtd

mtd = mtd.MtD("homeserver.yaml")

app = FastAPI()


@app.get('/')
async def root():
    return {'API_root': 'Default response to [matrix.digitalmedcare.de:8001]', 'data': 0}


@app.get('/test_api/{parameter}')
async def test_api(parameter: str):
    return {"function_name": test_api.__name__, 'parameter': parameter, 'return_value': mtd.api_test(parameter)}


@app.get('/test_token/{token}')
async def test_token(token: str):
    return {"function_name": test_token.__name__, 'token': token, 'valid': mtd.valid_token(token)}


@app.get('/delete_user/{username}')
async def delete_user(username: str):
    return {delete_user.__name__: 'Deleting user', 'user': username, 'call': mtd.api_test(username)}
