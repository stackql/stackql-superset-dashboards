
import argparse
import json
import os
import requests

from jinja2 import Template

class SupersetBasicAuthClient(object):

    def __init__(
            self, 
            username, 
            password, 
            protocol='http', 
            host='localhost', 
            port=8088,
            **kwargs):
        self._host = host
        self._protocol = protocol
        self._port = port
        self._username = username
        self._password = password
        self._session = None
    
    def _get_csrf_token(self) -> str:
        return self._session.get(self._adorn_url('/api/v1/security/csrf_token/')).json().get('result')


    def _get_token(self) -> dict:
        self._session = requests.Session()
        request_body = {
            'username': self._username,
            'password': self._password
        }
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}
        auth_response = requests.post(self._adorn_url('/login/'), data=request_body, headers=headers, allow_redirects=False)
        set_cookie = auth_response.headers.get('Set-Cookie', None)
        session_id = set_cookie.split(';')[0].split('=')[1]
        self._session.cookies.update({'session': session_id})
        return {}
    
    def _refresh_token(self) -> dict:
        auth_dict = requests.post(self._adorn_url('/api/v1/security/refresh'), headers={'Authorization', f'Bearer {self._refresh_token}'}).json()
        self._token = auth_dict.get('access_token')
        self._refresh_token = auth_dict.get('refresh_token')
        return auth_dict
    
    def _adorn_kwargs(self, **kwargs) -> dict:
        self._get_token()
        headers = kwargs.get('headers', {})
        headers['Authorization'] = f'Bearer {self._token}'
        kwargs['headers'] = headers
        return kwargs

    def _adorn_url(self, url :str) -> str:
        return f'{self._protocol}://{self._host}:{self._port}{url}'

    def get(self, url :str, *args, **kwargs) -> requests.Response:
        # kwargs = self._adorn_kwargs(**kwargs)
        self._get_token()
        return self._session.get(self._adorn_url(url), *args, **kwargs)

    def post(self, url :str, *args, **kwargs) -> requests.Response:
        # kwargs = self._adorn_kwargs(**kwargs)
        self._get_token()
        return self._session.post(self._adorn_url(url), *args, **kwargs)

    def put(self, url :str, *args, **kwargs) -> requests.Response:
        # kwargs = self._adorn_kwargs(**kwargs)
        self._get_token()
        return self._session.put(self._adorn_url(url), *args, **kwargs)

    def delete(self, url :str, *args, **kwargs) -> requests.Response:
        # kwargs = self._adorn_kwargs(**kwargs)
        self._get_token()
        return self._session.delete(self._adorn_url(url), *args, **kwargs)


def main():
    args = parser.parse_args()
    resource_templates_dir = args.resource_template_dir
    client = SupersetBasicAuthClient(args.username, args.password, port=args.port)
    get_me = client.get('/api/v1/me/')
    me = get_me.json()
    user_id = me.get('result', {}).get('id')
    if user_id is None:
        raise Exception('no user found')
    assert get_me.status_code < 300
    get_databases = client.get('/api/v1/database/')
    assert get_databases.status_code < 300
    databases = get_databases.json()
    db_descriptions = databases.get('result', [])
    stackql_db_id = -1
    for db in db_descriptions:
        if db.get('database_name') == 'StackQL':
            stackql_db_id = db.get('id', -1)
            break
    assert stackql_db_id > -1
    with open(os.path.join(resource_templates_dir, 'dashboards.json.jinja'), 'r') as f:
        dashboards_template_raw = f.read() 
    dashboards_template = Template(dashboards_template_raw)
    rendered_dashboards = json.loads(
        dashboards_template.render(
            {
                'user_id': user_id
            }
        )
    )
    with open(os.path.join(resource_templates_dir, 'datasets.json.jinja'), 'r') as f:
        datasets_template_raw = f.read() 
    datasets_template = Template(datasets_template_raw)
    rendered_datasets = json.loads(
        datasets_template.render(
            {
                'user_id': user_id,
                'stackql_db_id': stackql_db_id
            }
        )
    )
    # print(
    #     rendered_datasets
    # )
    print(f'current user id = {user_id}')
    print(f'stackql db id = {stackql_db_id}')

    created_datasets = {}
    for k, ds in rendered_datasets.items():
        create_response = client.post('/api/v1/dataset/', json=ds)
        assert create_response.status_code < 300
        print(create_response.json())
        created_id = create_response.json().get('id', -1)
        if created_id != -1:
            created_datasets[k] = {"id": created_id}
        print(f'created dataset with table_name = "{ds.get("table_name")}"')

    created_dashboards = {}
    for k, dashboard in rendered_dashboards.items():
        create_response = client.post('/api/v1/dashboard/', json=dashboard)
        assert create_response.status_code < 300
        print(create_response.json())
        print(f'created dashboard with table_name = "{dashboard.get("dashboard_title")}"')
        created_id = create_response.json().get('id', -1)
        if created_id != -1:
            created_dashboards[k] = {"id": created_id}

    with open(os.path.join(resource_templates_dir, 'charts.json.jinja'), 'r') as f:
        charts_template_raw = f.read() 
    charts_template = Template(charts_template_raw)
    rendered_charts = json.loads(
        charts_template.render(
            {
                'user_id': user_id,
                'stackql_db_id': stackql_db_id,
                'created_datasets': created_datasets,
                'created_dashboards': created_dashboards
            }
        )
    )
    print(
        json.dumps({
                'user_id': user_id,
                'stackql_db_id': stackql_db_id,
                'created_datasets': created_datasets,
                'created_dashboards': created_dashboards
        })
    )
    print(rendered_charts)

    created_charts = []
    for chart in rendered_charts:
        create_response = client.post('/api/v1/chart/', json=chart)
        assert create_response.status_code < 300
        print(f'created chart with description = "{chart.get("slice_name")}"')
        response_dict = create_response.json()
        created_id = response_dict.get('results', {}).get('id', -1)
        if created_id != -1:
            created_charts.append(created_id)

    print('bootstrap completed')
    exit(0)

parser = argparse.ArgumentParser(description='Process some test config.')
parser.add_argument(
    'username'
)
parser.add_argument(
    'password'
)
parser.add_argument(
    '--port', 
    type=int,
    default=8088,
    help='network port'
)
parser.add_argument(
    '--protocol', 
    type=str,
    default='http',
    help='L7 protocol'
)
parser.add_argument(
    '--host', 
    type=str,
    default='localhost',
    help='network host'
)
parser.add_argument(
    '--resource_template_dir', 
    type=str,
    default= os.path.join(os.path.dirname(os.path.realpath(__file__)), 'resources', 'standard'),
    help='location for jinja resources templates'
)

if __name__ == '__main__':
    main()

