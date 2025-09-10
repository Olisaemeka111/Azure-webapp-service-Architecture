# Deployment Examples - Azure App Service Architecture

## 🚀 **Real-World Deployment Examples**

This guide provides practical examples of how to deploy different types of applications to your Azure App Service Architecture.

---

## 📋 **Example 1: ASP.NET Core Web API**

### **1. Create a New Web API Project**
```bash
# Create new Web API project
dotnet new webapi -n MyWebAPI
cd MyWebAPI

# Add Entity Framework
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools

# Add Application Insights
dotnet add package Microsoft.ApplicationInsights.AspNetCore
```

### **2. Configure Database Context**
```csharp
// Models/Product.cs
public class Product
{
    public int Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Data/ApplicationDbContext.cs
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }
    
    public DbSet<Product> Products { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Product>()
            .HasKey(p => p.Id);
            
        modelBuilder.Entity<Product>()
            .Property(p => p.Price)
            .HasColumnType("decimal(18,2)");
    }
}
```

### **3. Configure Services**
```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add Entity Framework
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Add Application Insights
builder.Services.AddApplicationInsightsTelemetry();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontDoor", policy =>
        policy.WithOrigins("https://azure-app-arch-prod-fd-endpoint-f9b6cxh4bqeshpce.z01.azurefd.net")
              .AllowAnyMethod()
              .AllowAnyHeader());
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowFrontDoor");
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### **4. Create API Controller**
```csharp
// Controllers/ProductsController.cs
[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ProductsController> _logger;
    
    public ProductsController(ApplicationDbContext context, ILogger<ProductsController> logger)
    {
        _context = context;
        _logger = logger;
    }
    
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Product>>> GetProducts()
    {
        _logger.LogInformation("Getting all products");
        return await _context.Products.ToListAsync();
    }
    
    [HttpGet("{id}")]
    public async Task<ActionResult<Product>> GetProduct(int id)
    {
        _logger.LogInformation("Getting product {ProductId}", id);
        var product = await _context.Products.FindAsync(id);
        
        if (product == null)
        {
            _logger.LogWarning("Product {ProductId} not found", id);
            return NotFound();
        }
        
        return product;
    }
    
    [HttpPost]
    public async Task<ActionResult<Product>> PostProduct(Product product)
    {
        _logger.LogInformation("Creating new product: {ProductName}", product.Name);
        
        product.CreatedAt = DateTime.UtcNow;
        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        
        _logger.LogInformation("Product {ProductId} created successfully", product.Id);
        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
    }
    
    [HttpPut("{id}")]
    public async Task<IActionResult> PutProduct(int id, Product product)
    {
        if (id != product.Id)
        {
            return BadRequest();
        }
        
        _logger.LogInformation("Updating product {ProductId}", id);
        _context.Entry(product).State = EntityState.Modified;
        
        try
        {
            await _context.SaveChangesAsync();
            _logger.LogInformation("Product {ProductId} updated successfully", id);
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ProductExists(id))
            {
                _logger.LogWarning("Product {ProductId} not found for update", id);
                return NotFound();
            }
            else
            {
                throw;
            }
        }
        
        return NoContent();
    }
    
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        _logger.LogInformation("Deleting product {ProductId}", id);
        var product = await _context.Products.FindAsync(id);
        
        if (product == null)
        {
            _logger.LogWarning("Product {ProductId} not found for deletion", id);
            return NotFound();
        }
        
        _context.Products.Remove(product);
        await _context.SaveChangesAsync();
        
        _logger.LogInformation("Product {ProductId} deleted successfully", id);
        return NoContent();
    }
    
    private bool ProductExists(int id)
    {
        return _context.Products.Any(e => e.Id == id);
    }
}
```

### **5. Configure Connection String**
```json
// appsettings.json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=azure-app-arch-prod-sql.database.windows.net;Database=appdb;User Id=sqladmin;Password=<your-password>;Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

### **6. Create and Run Migrations**
```bash
# Add migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update
```

### **7. Deploy to Azure**
```bash
# Build and publish
dotnet publish -c Release -o ./publish

# Create deployment package
cd publish
zip -r ../mywebapi.zip .

# Deploy using Azure CLI
az webapp deployment source config-zip \
  --resource-group azure-app-arch-prod-rg \
  --name azure-app-arch-prod-app \
  --src ../mywebapi.zip
```

---

## 📋 **Example 2: React Frontend with .NET Backend**

### **1. Create React Frontend**
```bash
# Create React app
npx create-react-app my-frontend
cd my-frontend

# Install additional packages
npm install axios
npm install @mui/material @emotion/react @emotion/styled
```

### **2. Create API Service**
```javascript
// src/services/api.js
import axios from 'axios';

const API_BASE_URL = 'https://azure-app-arch-prod-fd-endpoint-f9b6cxh4bqeshpce.z01.azurefd.net/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const productService = {
  getAll: () => api.get('/products'),
  getById: (id) => api.get(`/products/${id}`),
  create: (product) => api.post('/products', product),
  update: (id, product) => api.put(`/products/${id}`, product),
  delete: (id) => api.delete(`/products/${id}`),
};

export default api;
```

### **3. Create Product Components**
```jsx
// src/components/ProductList.jsx
import React, { useState, useEffect } from 'react';
import { productService } from '../services/api';
import {
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  Box,
  CircularProgress,
  Alert
} from '@mui/material';

const ProductList = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const response = await productService.getAll();
      setProducts(response.data);
    } catch (err) {
      setError('Failed to fetch products');
      console.error('Error fetching products:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    try {
      await productService.delete(id);
      setProducts(products.filter(p => p.id !== id));
    } catch (err) {
      setError('Failed to delete product');
      console.error('Error deleting product:', err);
    }
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" p={4}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        {error}
      </Alert>
    );
  }

  return (
    <Box p={2}>
      <Typography variant="h4" gutterBottom>
        Products
      </Typography>
      <Grid container spacing={2}>
        {products.map((product) => (
          <Grid item xs={12} sm={6} md={4} key={product.id}>
            <Card>
              <CardContent>
                <Typography variant="h6" component="div">
                  {product.name}
                </Typography>
                <Typography color="text.secondary">
                  ${product.price}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Created: {new Date(product.createdAt).toLocaleDateString()}
                </Typography>
                <Button
                  color="error"
                  onClick={() => handleDelete(product.id)}
                  sx={{ mt: 1 }}
                >
                  Delete
                </Button>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    </Box>
  );
};

export default ProductList;
```

### **4. Deploy Frontend to Static Web Apps**
```bash
# Build React app
npm run build

# Deploy to Azure Static Web Apps
az staticwebapp create \
  --name my-frontend-app \
  --resource-group azure-app-arch-prod-rg \
  --source https://github.com/your-username/my-frontend \
  --location "Central US" \
  --branch main \
  --app-location "/" \
  --output-location "build"
```

---

## 📋 **Example 3: Microservices Architecture**

### **1. User Service**
```csharp
// UserService/Controllers/UsersController.cs
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<UsersController> _logger;
    
    [HttpGet]
    public async Task<ActionResult<IEnumerable<User>>> GetUsers()
    {
        _logger.LogInformation("Getting all users");
        return Ok(await _userService.GetAllAsync());
    }
    
    [HttpPost]
    public async Task<ActionResult<User>> CreateUser(User user)
    {
        _logger.LogInformation("Creating user: {Email}", user.Email);
        var createdUser = await _userService.CreateAsync(user);
        return CreatedAtAction(nameof(GetUser), new { id = createdUser.Id }, createdUser);
    }
}
```

### **2. Order Service**
```csharp
// OrderService/Controllers/OrdersController.cs
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;
    private readonly IUserServiceClient _userServiceClient;
    private readonly ILogger<OrdersController> _logger;
    
    [HttpPost]
    public async Task<ActionResult<Order>> CreateOrder(Order order)
    {
        _logger.LogInformation("Creating order for user: {UserId}", order.UserId);
        
        // Validate user exists
        var user = await _userServiceClient.GetUserAsync(order.UserId);
        if (user == null)
        {
            return BadRequest("User not found");
        }
        
        var createdOrder = await _orderService.CreateAsync(order);
        return CreatedAtAction(nameof(GetOrder), new { id = createdOrder.Id }, createdOrder);
    }
}
```

### **3. API Gateway Configuration**
```yaml
# ocelot.json
{
  "Routes": [
    {
      "DownstreamPathTemplate": "/api/users/{everything}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "azure-app-arch-prod-app.azurewebsites.net",
          "Port": 443
        }
      ],
      "UpstreamPathTemplate": "/api/users/{everything}",
      "UpstreamHttpMethod": [ "GET", "POST", "PUT", "DELETE" ]
    },
    {
      "DownstreamPathTemplate": "/api/orders/{everything}",
      "DownstreamScheme": "https",
      "DownstreamHostAndPorts": [
        {
          "Host": "azure-app-arch-prod-app.azurewebsites.net",
          "Port": 443
        }
      ],
      "UpstreamPathTemplate": "/api/orders/{everything}",
      "UpstreamHttpMethod": [ "GET", "POST", "PUT", "DELETE" ]
    }
  ]
}
```

---

## 📋 **Example 4: Containerized Application**

### **1. Create Dockerfile**
```dockerfile
# Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["MyApp.csproj", "."]
RUN dotnet restore "MyApp.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "MyApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MyApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

### **2. Deploy to Container Registry**
```bash
# Build and tag image
docker build -t myapp:latest .
docker tag myapp:latest myregistry.azurecr.io/myapp:latest

# Push to Azure Container Registry
az acr login --name myregistry
docker push myregistry.azurecr.io/myapp:latest
```

### **3. Deploy to App Service**
```bash
# Configure App Service for containers
az webapp config container set \
  --name azure-app-arch-prod-app \
  --resource-group azure-app-arch-prod-rg \
  --docker-custom-image-name myregistry.azurecr.io/myapp:latest
```

---

## 📋 **Example 5: Background Jobs with Azure Functions**

### **1. Create Azure Function**
```csharp
// Functions/ProcessOrderFunction.cs
public class ProcessOrderFunction
{
    private readonly ILogger<ProcessOrderFunction> _logger;
    private readonly IOrderService _orderService;
    
    public ProcessOrderFunction(ILogger<ProcessOrderFunction> logger, IOrderService orderService)
    {
        _logger = logger;
        _orderService = orderService;
    }
    
    [FunctionName("ProcessOrder")]
    public async Task Run([ServiceBusTrigger("orders", Connection = "ServiceBusConnection")] string orderJson)
    {
        _logger.LogInformation("Processing order: {OrderJson}", orderJson);
        
        var order = JsonSerializer.Deserialize<Order>(orderJson);
        await _orderService.ProcessOrderAsync(order);
        
        _logger.LogInformation("Order processed successfully: {OrderId}", order.Id);
    }
}
```

### **2. Deploy Function App**
```bash
# Create Function App
az functionapp create \
  --resource-group azure-app-arch-prod-rg \
  --consumption-plan-location "West US 2" \
  --runtime dotnet \
  --runtime-version 6 \
  --functions-version 4 \
  --name my-function-app \
  --storage-account mystorageaccount
```

---

## 🔧 **Deployment Scripts**

### **1. Automated Deployment Script**
```bash
#!/bin/bash
# deploy.sh

set -e

echo "🚀 Starting deployment..."

# Variables
RESOURCE_GROUP="azure-app-arch-prod-rg"
APP_NAME="azure-app-arch-prod-app"
SQL_SERVER="azure-app-arch-prod-sql"
DATABASE="appdb"

# Build application
echo "📦 Building application..."
dotnet build --configuration Release

# Run tests
echo "🧪 Running tests..."
dotnet test

# Publish application
echo "📤 Publishing application..."
dotnet publish --configuration Release --output ./publish

# Create deployment package
echo "📦 Creating deployment package..."
cd publish
zip -r ../deployment.zip .
cd ..

# Deploy to Azure
echo "🚀 Deploying to Azure..."
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --src deployment.zip

# Run database migrations
echo "🗄️ Running database migrations..."
az webapp config connection-string set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_NAME \
  --connection-string-type SQLServer \
  --settings DefaultConnection="Server=$SQL_SERVER.database.windows.net;Database=$DATABASE;User Id=sqladmin;Password=<password>;Encrypt=true;"

# Verify deployment
echo "✅ Verifying deployment..."
curl -f https://azure-app-arch-prod-fd-endpoint-f9b6cxh4bqeshpce.z01.azurefd.net/api/health

echo "🎉 Deployment completed successfully!"
```

### **2. CI/CD Pipeline**
```yaml
# .github/workflows/deploy.yml
name: Deploy Application

on:
  push:
    branches: [ main ]
    paths: [ 'src/**' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: '6.0.x'
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --configuration Release --no-restore
    
    - name: Test
      run: dotnet test --configuration Release --no-build --verbosity normal
    
    - name: Publish
      run: dotnet publish --configuration Release --output ./publish
    
    - name: Deploy to Azure
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'azure-app-arch-prod-app'
        publish-profile: ${{ secrets.AZUREAPPSERVICE_PUBLISHPROFILE }}
        package: './publish'
    
    - name: Run database migrations
      run: |
        dotnet ef database update --connection "Server=azure-app-arch-prod-sql.database.windows.net;Database=appdb;User Id=sqladmin;Password=${{ secrets.SQL_PASSWORD }};Encrypt=true;"
```

---

## 📊 **Monitoring and Observability**

### **1. Custom Metrics**
```csharp
// Services/MetricsService.cs
public class MetricsService
{
    private readonly TelemetryClient _telemetryClient;
    
    public MetricsService(TelemetryClient telemetryClient)
    {
        _telemetryClient = telemetryClient;
    }
    
    public void TrackOrderCreated(Order order)
    {
        _telemetryClient.TrackEvent("OrderCreated", new Dictionary<string, string>
        {
            ["OrderId"] = order.Id.ToString(),
            ["UserId"] = order.UserId.ToString(),
            ["Amount"] = order.TotalAmount.ToString()
        });
    }
    
    public void TrackApiCall(string endpoint, int responseTime, int statusCode)
    {
        _telemetryClient.TrackMetric("ApiResponseTime", responseTime, new Dictionary<string, string>
        {
            ["Endpoint"] = endpoint,
            ["StatusCode"] = statusCode.ToString()
        });
    }
}
```

### **2. Health Checks**
```csharp
// Program.cs
builder.Services.AddHealthChecks()
    .AddSqlServer(connectionString, name: "sql")
    .AddAzureKeyVault(keyVaultUri, name: "keyvault")
    .AddCheck<CustomHealthCheck>("custom");

app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});
```

---

## ✅ **Summary**

These examples demonstrate how to:

1. **Deploy ASP.NET Core Web APIs** with Entity Framework
2. **Create React frontends** that consume your APIs
3. **Build microservices architectures** with API gateways
4. **Containerize applications** for consistent deployment
5. **Implement background processing** with Azure Functions
6. **Set up automated CI/CD pipelines** for continuous deployment
7. **Add comprehensive monitoring** and health checks

Your Azure App Service Architecture is ready to support any of these deployment patterns! 🚀
