"""
Azure Function App - Employee Management API
Backend for the DTE Employee Management System
"""
import azure.functions as func
import json
import logging
import os
import uuid
from datetime import datetime

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Cosmos DB connection (using Azure SDK)
from azure.cosmos import CosmosClient, PartitionKey, exceptions

def get_cosmos_client():
    """Get Cosmos DB client using endpoint and key from environment"""
    endpoint = os.environ.get("CosmosDbEndpoint")
    # Try managed identity first, fall back to connection string
    try:
        from azure.identity import DefaultAzureCredential
        credential = DefaultAzureCredential()
        return CosmosClient(endpoint, credential=credential)
    except Exception:
        # Fall back to connection string if managed identity fails
        connection_string = os.environ.get("CosmosDbConnectionString")
        if connection_string:
            return CosmosClient.from_connection_string(connection_string)
        raise Exception("No valid Cosmos DB credentials found")

def get_container():
    """Get the employees container"""
    client = get_cosmos_client()
    database_name = os.environ.get("CosmosDbDatabaseName", "employeedb")
    container_name = os.environ.get("CosmosDbContainerName", "employees")
    database = client.get_database_client(database_name)
    return database.get_container_client(container_name)


# ============================================================================
# Health Check
# ============================================================================
@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint"""
    return func.HttpResponse(
        json.dumps({"status": "healthy", "timestamp": datetime.utcnow().isoformat()}),
        mimetype="application/json",
        status_code=200
    )


# ============================================================================
# GET /api/employees - List all employees
# ============================================================================
@app.route(route="employees", methods=["GET"])
def get_employees(req: func.HttpRequest) -> func.HttpResponse:
    """Get all employees with optional filtering"""
    try:
        container = get_container()
        
        # Get query parameters
        department = req.params.get("department")
        search = req.params.get("search")
        
        # Build query
        if department:
            query = "SELECT * FROM c WHERE c.department = @department"
            parameters = [{"name": "@department", "value": department}]
            items = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))
        elif search:
            query = "SELECT * FROM c WHERE CONTAINS(LOWER(c.firstName), LOWER(@search)) OR CONTAINS(LOWER(c.lastName), LOWER(@search)) OR CONTAINS(LOWER(c.email), LOWER(@search))"
            parameters = [{"name": "@search", "value": search}]
            items = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))
        else:
            items = list(container.read_all_items())
        
        return func.HttpResponse(
            json.dumps({"employees": items, "count": len(items)}),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error getting employees: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )


# ============================================================================
# GET /api/employees/{id} - Get single employee
# ============================================================================
@app.route(route="employees/{id}", methods=["GET"])
def get_employee(req: func.HttpRequest) -> func.HttpResponse:
    """Get a single employee by ID"""
    try:
        employee_id = req.route_params.get("id")
        container = get_container()
        
        # Query by id (need to search across partitions)
        query = "SELECT * FROM c WHERE c.id = @id"
        parameters = [{"name": "@id", "value": employee_id}]
        items = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))
        
        if not items:
            return func.HttpResponse(
                json.dumps({"error": "Employee not found"}),
                mimetype="application/json",
                status_code=404
            )
        
        return func.HttpResponse(
            json.dumps(items[0]),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error getting employee: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )


# ============================================================================
# POST /api/employees - Create new employee
# ============================================================================
@app.route(route="employees", methods=["POST"])
def create_employee(req: func.HttpRequest) -> func.HttpResponse:
    """Create a new employee"""
    try:
        body = req.get_json()
        
        # Validate required fields
        required_fields = ["firstName", "lastName", "email", "department"]
        for field in required_fields:
            if field not in body:
                return func.HttpResponse(
                    json.dumps({"error": f"Missing required field: {field}"}),
                    mimetype="application/json",
                    status_code=400
                )
        
        container = get_container()
        
        # Create employee document
        employee = {
            "id": str(uuid.uuid4()),
            "firstName": body["firstName"],
            "lastName": body["lastName"],
            "email": body["email"],
            "department": body["department"],
            "position": body.get("position", ""),
            "phone": body.get("phone", ""),
            "hireDate": body.get("hireDate", datetime.utcnow().strftime("%Y-%m-%d")),
            "salary": body.get("salary", 0),
            "isActive": True,
            "createdAt": datetime.utcnow().isoformat(),
            "updatedAt": datetime.utcnow().isoformat()
        }
        
        # Insert into Cosmos DB
        created = container.create_item(body=employee)
        
        return func.HttpResponse(
            json.dumps(created),
            mimetype="application/json",
            status_code=201
        )
    except Exception as e:
        logging.error(f"Error creating employee: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )


# ============================================================================
# PUT /api/employees/{id} - Update employee
# ============================================================================
@app.route(route="employees/{id}", methods=["PUT"])
def update_employee(req: func.HttpRequest) -> func.HttpResponse:
    """Update an existing employee"""
    try:
        employee_id = req.route_params.get("id")
        body = req.get_json()
        container = get_container()
        
        # Find existing employee
        query = "SELECT * FROM c WHERE c.id = @id"
        parameters = [{"name": "@id", "value": employee_id}]
        items = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))
        
        if not items:
            return func.HttpResponse(
                json.dumps({"error": "Employee not found"}),
                mimetype="application/json",
                status_code=404
            )
        
        existing = items[0]
        
        # Update fields
        existing["firstName"] = body.get("firstName", existing["firstName"])
        existing["lastName"] = body.get("lastName", existing["lastName"])
        existing["email"] = body.get("email", existing["email"])
        existing["department"] = body.get("department", existing["department"])
        existing["position"] = body.get("position", existing.get("position", ""))
        existing["phone"] = body.get("phone", existing.get("phone", ""))
        existing["salary"] = body.get("salary", existing.get("salary", 0))
        existing["isActive"] = body.get("isActive", existing.get("isActive", True))
        existing["updatedAt"] = datetime.utcnow().isoformat()
        
        # Replace in Cosmos DB
        updated = container.replace_item(item=existing["id"], body=existing)
        
        return func.HttpResponse(
            json.dumps(updated),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error updating employee: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )


# ============================================================================
# DELETE /api/employees/{id} - Delete employee
# ============================================================================
@app.route(route="employees/{id}", methods=["DELETE"])
def delete_employee(req: func.HttpRequest) -> func.HttpResponse:
    """Delete an employee (soft delete)"""
    try:
        employee_id = req.route_params.get("id")
        container = get_container()
        
        # Find existing employee
        query = "SELECT * FROM c WHERE c.id = @id"
        parameters = [{"name": "@id", "value": employee_id}]
        items = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))
        
        if not items:
            return func.HttpResponse(
                json.dumps({"error": "Employee not found"}),
                mimetype="application/json",
                status_code=404
            )
        
        existing = items[0]
        
        # Soft delete - mark as inactive
        existing["isActive"] = False
        existing["deletedAt"] = datetime.utcnow().isoformat()
        existing["updatedAt"] = datetime.utcnow().isoformat()
        
        container.replace_item(item=existing["id"], body=existing)
        
        return func.HttpResponse(
            json.dumps({"message": "Employee deleted successfully"}),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error deleting employee: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )


# ============================================================================
# GET /api/departments - Get department statistics
# ============================================================================
@app.route(route="departments", methods=["GET"])
def get_departments(req: func.HttpRequest) -> func.HttpResponse:
    """Get department statistics"""
    try:
        container = get_container()
        
        # Get all active employees
        query = "SELECT c.department FROM c WHERE c.isActive = true"
        items = list(container.query_items(query=query, enable_cross_partition_query=True))
        
        # Count by department
        dept_counts = {}
        for item in items:
            dept = item.get("department", "Unknown")
            dept_counts[dept] = dept_counts.get(dept, 0) + 1
        
        departments = [{"name": k, "count": v} for k, v in dept_counts.items()]
        
        return func.HttpResponse(
            json.dumps({"departments": departments}),
            mimetype="application/json",
            status_code=200
        )
    except Exception as e:
        logging.error(f"Error getting departments: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": str(e)}),
            mimetype="application/json",
            status_code=500
        )
