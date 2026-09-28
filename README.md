# pollux-server
**_Pollux_** is a hobby web-app project aimed at replicating some of the capabilities of file management software like _Google Drive_. 
The **pollux-server** is the back-end component of this project.
The fron-end companion to this can be found here [pollux-client github](https://github.com/Rhythm-Mondal/pollux-client). 

# Development setup

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with Docker Compose enabled.
- GNU Make. On Windows, use the Make installation provided by your development environment or run the equivalent `docker compose` commands directly.

## First run

Create a local environment file from the committed template:

```bash
make env
```

Review `.env` and replace the sample `SECRET_KEY` and database password before using the project outside local development.

Validate the Compose configuration, then build and start the API and PostgreSQL services:

```bash
make check
make up
```

The API is available at `http://localhost:8000`, with interactive API documentation at `http://localhost:8000/docs`. Source changes reload the API automatically. PostgreSQL data persists in the local `postgres_data` Docker volume, and the required `ltree` extension is created when that volume is initialized.

## Daily commands

```bash
make up-d       # start in the background
make logs-api   # follow API logs
make logs-db    # follow PostgreSQL logs
make ps         # show service status
make down       # stop the development stack
```

Run `make api-shell` to open a shell in the API container, or `make db-shell` to open `psql` in the PostgreSQL container.

`make db-reset` removes the local PostgreSQL volume and recreates the database. It permanently deletes local development data.


# API definitions
Below is a list of API's used by this system. the `base url` will be omitted in all APIs only `method`, `path`, `body`, `params` will be mentioned. 
This will also assume that all API will require Bearer token authorization in the headers unless specified otherwise.

## 1. User related API's

### 1.1 User Registration
```
POST /register

headers: ()
body: {
    email: str
    name: str
    password: str
}

responses:
400 Bad request
201 Ok
```

### 1.2 User Login
```
POST /login

headers: ()
body: {
    email: str
    password: str
}

responses:
400 Bad request
404 Email or Password is Invalid
200 Ok
{
    access_token: str
}
```

### 1.3 Search Users
```
POST /users/search

body: {
    text: str        [optional][3-256 charcters][name prefix or email]
    page: int        [optional][defaults to 1]
    page_size: int   [optional][defaults to 10]
}

responses:
400 Bad request
200 Ok
{
    total: int
    users: [
        ...,
        {
            id: uuid
            name: str
            email: str
        },
        ...
    ]
}

```

## 2. Space management API's

### 2.1 Create Spaces
```
POST /spaces

body:{
    name: str  [3-128 characters]
}

responses:
400 Bad Request
401 Unauthorized
409 A space with the same name already exists
201 Ok
```

### 2.2 List Spaces
```
GET /spaces

params: {
    page: int        [optional][if page_size is sent defaults to 1]
    page_size: int   [optional][if page is provided defaults to 10]
}

responses:
400 Bad request
401 Unauthorized
404 Not found
200 Ok
{
    total: int
    spaces: [
        ...,
        {
            id: uuid
            name: str
            created_at: datetime
            updated_at: datetime
        },
        ...
    ]
}

The omission of both page and page_size will be interpreted as 'do not paginate'.
This will be assumed for all future paginated queries
```

### 2.3 Rename Space
```
PATCH /spaces/{space_id}

body: {
    name: str
}

responses:
400 Bad request
401 Unauthorized
404 Not found
409 Space with same name already exists
200 Ok

```


### 2.4 Delete Space
```
DELETE /spaces/{space_id}

params: {
    delete_content: true
}

responses:
400 Bad Request
401 Unauthorized
403 Can not delete this space
403 Can not delete default space
404 Not found
409 Space contains files/folders do you wish delete those as well
200 Ok
```

## 3. File/Folder management API's

### 3.1 Upload File
```
POST /spaces/me/nodes/files
POST /spaces/{space_id}/nodes/files

body: {
    name: str
    parent_id: int   [optional]
    overwrite: bool  [optional]
}

responses:
400 Bad request
401 Unauthorized
403 Can not upload files here
409 A file with same name already exists
200 Ok
```

### 3.2 Create Folder
```
POST /spaces/me/nodes/folders
POST /spaces/{space_id}/nodes/folders

body: {
    name: str
    parent_id: int   [optional]
}

responses:
400 Bad request
401 Unauthorized
403 Can not upload folders here
409 A folder with same name already exists
200 Ok
```

### 3.3 Get File/Folder Meta
```
GET /spaces/me/nodes/{node_id}/info
GET /spaces/{space_id}/nodes/{node_id}/info

responses:
400 Bad request
401 Unauthorized
404 Not found
200 Ok
{
    id: int
    parent_id: int
    space_id: uuid
    type: str
    name: str
    uploader_id: uuid
    created_at: datetime
    updated_at: datetime
    is_shared: bool
    * additional file data like mimetype, size
}
```

### 3.4 List Space Content
```
GET /spaces/me/nodes
GET /spaces/{space_id}/nodes

params: {
    page: int
    page_size: int
}

resposes:
400 Bad Request
401 Unauthorized
404 Not found
200 Ok
{
    total: int
    nodes: [
        ...,
        {
            id: int
            parent_id: int / null
            space_id: uuid
            type: str              [file or folder]
            name: str
            uploader_id: uuid
            created_at: datetime
            updated_at: datetime
            is_shared: bool
            can: {
                open: bool
                upload: bool
                download: bool,
                rename: bool,
                copy: bool,
                cut: bool,
                paste: bool,
                archive: bool,
                delete: bool,
                share: bool,
            }
        },
        ...
    ]
}
```

### 3.5 List Folder Content
```
GET /spaces/me/nodes/{node_id}
GET /spaces/{space_id}/nodes/{node_id}

params: {
    *text: str       [optional][not implemented yet]
    page: int
    page_size: int
}

resposes:
400 Bad Request
401 Unauthorized
404 Not found
200 Ok
{
    total: int
    nodes: [
        ...,
        {
            id: int
            parent_id: int / null
            space_id: uuid
            type: str              [file or folder]
            name: str
            uploader_id: uuid
            created_at: datetime
            updated_at: datetime
            is_shared: bool
            can: {
                open: bool
                upload: bool
                download: bool,
                rename: bool,
                copy: bool,
                cut: bool,
                paste: bool,
                archive: bool,
                delete: bool,
                share: bool,
            }
        },
        ...
    ]
}
```

### 3.6 Rename File/Folder
```
PATCH /spaces/me/nodes/{node_id}
PATCH /spaces/{space_id}/nodes/{node_id}

body: {
    name: str
}

responses
400 Bad request
401 Unauthorized
404 Not found
409 A file/folder with the same name already exits
200 Ok
```

### 3.7 Copy File/Folder
```
PUT /spaces/me/nodes/{node_id}/copy
PUT /spaces/{space_id}/nodes/{node_id}/copy

body: {
    *overwrite: bool  [optional][unimplemented]
    *merge: bool      [optional][unimplemented]
    name: str         [optional][rename on destination]
    parent_id: int    [optional][destination parent]
    space_id: uuid    [destination space]
}

responses:
400 Bad request
401 Unauthorized
403 Can not copy to this location
404 Not found
409 Destination is not a folder
409 Destination folder is archived
409 A file / folder with the same name already exists
409 Archived file / folder can not be moved
200 Ok

** It is assumed for folders all children are also copied
```

### 3.8 Move File/Folder
```
PUT /spaces/me/nodes/{node_id}/move
PUT /spaces/{space_id}/nodes/{node_id}/move

body: {
    *overwrite: bool  [optional][unimplemented]
    *merge: bool      [optional][unimplemented]
    name: str         [optional][rename on destination]
    parent_id: int    [optional][destination parent]
}

responses:
400 Bad request
401 Unauthorized
403 Can not move from this location
403 Can not move to this location
404 Not found
409 Destination is not a folder
409 Destination folder is archived
409 A file / folder with the same name already exists
409 Archived file / folder can not be moved
409 Can not move to ones children
200 Ok

** It is assumed for folders all children are also moved
```

### 3.9 Archive File/Folder
```
PATCH /spaces/me/nodes/{node_id}/archive
PATCH /spaces/{space_id}/nodes/{node_id}/archive

responses:
400 Bad request
401 Unauthorized
403 Can not archive this file / folder
404 Not found
409 File / Folder already archived
200 Ok
```

### 3.10 Delete File/Folder
```
DELETE /spaces/me/nodes/{node_id}
DELETE /spaces/{space_id}/nodes/{node_id}

params: {
    recursive: bool
}

responses:
400 Bad request
401 Unauthorized
404 Not found
409 Folder contains content delete content as well
200 Ok
```

## 4. Share related API's

### 4.1 Share File/Folder
```
PUT /spaces/me/nodes/{node_id}/shares
PUT /spaces/{space_id}/nodes/{node_id}/shares

body: {
    shares: [
        ...,
        {
            user_id: uuid
            permission: str  [one of viewer, editor, admin]
        },
        ...
    ]
}

responses:
400 Bad request
401 Unauthorized
403 Can not share this file / folder
404 Not found
```

### 4.2 List Shared Users
```
GET /spaces/me/nodes/{node_id}/shares
GET /spaces/{space_id}/nodes/{node_id}/shares

params: {
    page: int
    page_size: int
}

responses:
400 Bad request
401 Unauthorized
404 Not found
200 Ok
{
    total: int
    shares: [
        ...,
        {
            user_id: uuid
            name: str
            permission: str  [one of viewer, editor, admin, owner]
        },
        ...
    ]
}
```

### 4.3 List Shared Files/Folders
```
GET /spaces/shares/list

params: {
    page: int
    page_size: int
}

responses:
400 Bad request
401 Unauthorized
404 Not found
200 Ok
{
    total: int
    nodes: [
        ...,
        {
            id: int
            parent_id: int / null
            space_id: uuid
            type: str              [file or folder]
            name: str
            uploader_id: uuid
            created_at: datetime
            updated_at: datetime
            is_shared: bool
            can: {
                open: bool
                upload: bool
                download: bool,
                rename: bool,
                copy: bool,
                cut: bool,
                paste: bool,
                archive: bool,
                delete: bool,
                share: bool,
            }
        },
        ...
    ]
}
```

## 5. Archive related API's

### 5.1 List Archived Files/Folders
```
GET /spaces/me/archives
GET /spaces/{space_id}/archives

params: {
    node_id: int    [optional][expand under folder] 
    page: int
    page_size: int
}

responses:
400 Bad request
401 Unauthorized
403 Can not view archives
200 Ok
{
    total: int
    nodes: [
        id: int
        parent_id: int / null
        space_id: uuid
        type: str              [file or folder]
        name: str
        uploader_id: uuid
        created_at: datetime
        updated_at: datetime
        is_shared: bool
        can: {
            restore: bool
            delete: bool
        }
    ]
}
```

### 5.2 Restore File/Folder
```
PATCH /spaces/me/nodes/{node_id}/restore
PATCH /spaces/{space_id}/nodes/{node_id}/restore

body: {
    name: str       [optional][3-128 characters]
    *overwrite: bool [optional][uninplemented]
}

responses:
400 Bad request
401 Unauthorized
404 Not found
409 File / Folder is not archived
409 A file / folder with the same name exist in the restore location, rename or overwrite
409 Parent folder is archived, restore parent first
200 Ok
```

