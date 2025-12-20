import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useNavigate, useParams } from 'react-router-dom';
import { QueryClient, QueryClientProvider, useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// API Configuration
const API_BASE_URL = window.REACT_APP_API_URL || process.env.REACT_APP_API_URL || '/api';

const queryClient = new QueryClient();

// API Functions
const api = {
  getEmployees: async (params = {}) => {
    const searchParams = new URLSearchParams(params).toString();
    const url = searchParams ? `${API_BASE_URL}/employees?${searchParams}` : `${API_BASE_URL}/employees`;
    const res = await fetch(url);
    if (!res.ok) throw new Error('Failed to fetch employees');
    return res.json();
  },
  getEmployee: async (id) => {
    const res = await fetch(`${API_BASE_URL}/employees/${id}`);
    if (!res.ok) throw new Error('Failed to fetch employee');
    return res.json();
  },
  createEmployee: async (data) => {
    const res = await fetch(`${API_BASE_URL}/employees`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to create employee');
    return res.json();
  },
  updateEmployee: async ({ id, data }) => {
    const res = await fetch(`${API_BASE_URL}/employees/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error('Failed to update employee');
    return res.json();
  },
  deleteEmployee: async (id) => {
    const res = await fetch(`${API_BASE_URL}/employees/${id}`, { method: 'DELETE' });
    if (!res.ok) throw new Error('Failed to delete employee');
    return res.json();
  },
  getDepartments: async () => {
    const res = await fetch(`${API_BASE_URL}/departments`);
    if (!res.ok) throw new Error('Failed to fetch departments');
    return res.json();
  },
};

// Header Component
function Header() {
  return (
    <header className="header">
      <h1>👥 Employee Management</h1>
      <nav>
        <Link to="/">Dashboard</Link>
        <Link to="/employees">Employees</Link>
        <Link to="/employees/new">Add Employee</Link>
      </nav>
    </header>
  );
}

// Dashboard Page
function Dashboard() {
  const { data: employeesData, isLoading: loadingEmployees } = useQuery({
    queryKey: ['employees'],
    queryFn: () => api.getEmployees(),
  });
  
  const { data: deptData, isLoading: loadingDepts } = useQuery({
    queryKey: ['departments'],
    queryFn: api.getDepartments,
  });

  if (loadingEmployees || loadingDepts) return <div className="loading">Loading...</div>;

  const employees = employeesData?.employees || [];
  const departments = deptData?.departments || [];

  return (
    <div className="container">
      <h2 style={{ marginBottom: '24px' }}>Dashboard</h2>
      
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-value">{employees.length}</div>
          <div className="stat-label">Total Employees</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{departments.length}</div>
          <div className="stat-label">Departments</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{employees.filter(e => e.isActive).length}</div>
          <div className="stat-label">Active Employees</div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">Department Summary</span>
        </div>
        <table className="table">
          <thead>
            <tr>
              <th>Department</th>
              <th>Employees</th>
            </tr>
          </thead>
          <tbody>
            {departments.map(dept => (
              <tr key={dept.name}>
                <td>{dept.name}</td>
                <td>{dept.count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// Employee List Page
function EmployeeList() {
  const [search, setSearch] = useState('');
  const [department, setDepartment] = useState('');
  const queryClient = useQueryClient();
  
  const { data, isLoading, error } = useQuery({
    queryKey: ['employees', { search, department }],
    queryFn: () => api.getEmployees({ search: search || undefined, department: department || undefined }),
  });

  const deleteMutation = useMutation({
    mutationFn: api.deleteEmployee,
    onSuccess: () => queryClient.invalidateQueries(['employees']),
  });

  if (isLoading) return <div className="loading">Loading employees...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  const employees = data?.employees || [];

  return (
    <div className="container">
      <div className="card">
        <div className="card-header">
          <span className="card-title">Employees ({employees.length})</span>
          <Link to="/employees/new"><button className="btn btn-primary">+ Add Employee</button></Link>
        </div>

        <div className="search-bar">
          <input
            type="text"
            placeholder="Search by name or email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <select value={department} onChange={(e) => setDepartment(e.target.value)}>
            <option value="">All Departments</option>
            <option value="Engineering">Engineering</option>
            <option value="Marketing">Marketing</option>
            <option value="Sales">Sales</option>
            <option value="HR">HR</option>
            <option value="Finance">Finance</option>
          </select>
        </div>

        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Department</th>
              <th>Position</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {employees.map(emp => (
              <tr key={emp.id}>
                <td>{emp.firstName} {emp.lastName}</td>
                <td>{emp.email}</td>
                <td>{emp.department}</td>
                <td>{emp.position || '-'}</td>
                <td>
                  <span className={`badge ${emp.isActive ? 'badge-success' : 'badge-warning'}`}>
                    {emp.isActive ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="actions">
                  <Link to={`/employees/${emp.id}`}><button className="btn btn-secondary">View</button></Link>
                  <Link to={`/employees/${emp.id}/edit`}><button className="btn btn-secondary">Edit</button></Link>
                  <button 
                    className="btn btn-danger" 
                    onClick={() => {
                      if (window.confirm('Are you sure you want to delete this employee?')) {
                        deleteMutation.mutate(emp.id);
                      }
                    }}
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// Employee Form Component
function EmployeeForm({ employee, onSubmit, isLoading }) {
  const [formData, setFormData] = useState({
    firstName: employee?.firstName || '',
    lastName: employee?.lastName || '',
    email: employee?.email || '',
    department: employee?.department || '',
    position: employee?.position || '',
    phone: employee?.phone || '',
    salary: employee?.salary || '',
    hireDate: employee?.hireDate || new Date().toISOString().split('T')[0],
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className="form-row">
        <div className="form-group">
          <label>First Name *</label>
          <input name="firstName" value={formData.firstName} onChange={handleChange} required />
        </div>
        <div className="form-group">
          <label>Last Name *</label>
          <input name="lastName" value={formData.lastName} onChange={handleChange} required />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Email *</label>
          <input type="email" name="email" value={formData.email} onChange={handleChange} required />
        </div>
        <div className="form-group">
          <label>Phone</label>
          <input name="phone" value={formData.phone} onChange={handleChange} />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Department *</label>
          <select name="department" value={formData.department} onChange={handleChange} required>
            <option value="">Select Department</option>
            <option value="Engineering">Engineering</option>
            <option value="Marketing">Marketing</option>
            <option value="Sales">Sales</option>
            <option value="HR">HR</option>
            <option value="Finance">Finance</option>
          </select>
        </div>
        <div className="form-group">
          <label>Position</label>
          <input name="position" value={formData.position} onChange={handleChange} />
        </div>
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Hire Date</label>
          <input type="date" name="hireDate" value={formData.hireDate} onChange={handleChange} />
        </div>
        <div className="form-group">
          <label>Salary</label>
          <input type="number" name="salary" value={formData.salary} onChange={handleChange} />
        </div>
      </div>

      <button type="submit" className="btn btn-primary" disabled={isLoading}>
        {isLoading ? 'Saving...' : 'Save Employee'}
      </button>
    </form>
  );
}

// Add Employee Page
function AddEmployee() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const mutation = useMutation({
    mutationFn: api.createEmployee,
    onSuccess: () => {
      queryClient.invalidateQueries(['employees']);
      navigate('/employees');
    },
  });

  return (
    <div className="container">
      <div className="card">
        <div className="card-header">
          <span className="card-title">Add New Employee</span>
        </div>
        {mutation.error && <div className="error">{mutation.error.message}</div>}
        <EmployeeForm onSubmit={mutation.mutate} isLoading={mutation.isLoading} />
      </div>
    </div>
  );
}

// Edit Employee Page
function EditEmployee() {
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  
  const { data: employee, isLoading, error } = useQuery({
    queryKey: ['employee', id],
    queryFn: () => api.getEmployee(id),
  });

  const mutation = useMutation({
    mutationFn: (data) => api.updateEmployee({ id, data }),
    onSuccess: () => {
      queryClient.invalidateQueries(['employees']);
      navigate('/employees');
    },
  });

  if (isLoading) return <div className="loading">Loading...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="container">
      <div className="card">
        <div className="card-header">
          <span className="card-title">Edit Employee</span>
        </div>
        {mutation.error && <div className="error">{mutation.error.message}</div>}
        <EmployeeForm employee={employee} onSubmit={mutation.mutate} isLoading={mutation.isLoading} />
      </div>
    </div>
  );
}

// View Employee Page
function ViewEmployee() {
  const { id } = useParams();
  
  const { data: employee, isLoading, error } = useQuery({
    queryKey: ['employee', id],
    queryFn: () => api.getEmployee(id),
  });

  if (isLoading) return <div className="loading">Loading...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="container">
      <div className="card">
        <div className="card-header">
          <span className="card-title">{employee.firstName} {employee.lastName}</span>
          <Link to={`/employees/${id}/edit`}><button className="btn btn-primary">Edit</button></Link>
        </div>
        
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
          <div><strong>Email:</strong> {employee.email}</div>
          <div><strong>Phone:</strong> {employee.phone || '-'}</div>
          <div><strong>Department:</strong> {employee.department}</div>
          <div><strong>Position:</strong> {employee.position || '-'}</div>
          <div><strong>Hire Date:</strong> {employee.hireDate || '-'}</div>
          <div><strong>Salary:</strong> {employee.salary ? `$${employee.salary.toLocaleString()}` : '-'}</div>
          <div><strong>Status:</strong> 
            <span className={`badge ${employee.isActive ? 'badge-success' : 'badge-warning'}`} style={{ marginLeft: '8px' }}>
              {employee.isActive ? 'Active' : 'Inactive'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}

// Main App
function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <Header />
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/employees" element={<EmployeeList />} />
          <Route path="/employees/new" element={<AddEmployee />} />
          <Route path="/employees/:id" element={<ViewEmployee />} />
          <Route path="/employees/:id/edit" element={<EditEmployee />} />
        </Routes>
      </Router>
    </QueryClientProvider>
  );
}

export default App;
