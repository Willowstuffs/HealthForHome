using Microsoft.EntityFrameworkCore;
using H4H.Data;
using H4H.Core.Interfaces;
using H4H.Data.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using H4H_API.Middleware;
using H4H_API.Services.Interfaces;
using H4H_API.Services.Implementations;
using H4H_API.Helpers;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Authorization;
using Swashbuckle.AspNetCore.SwaggerGen;

var builder = WebApplication.CreateBuilder(args);

// aby uniknac problem�w z datami w Npgsql (np. przy DateTimeOffset), ustawiamy legacy timestamp behavior
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

// Add services to the container.
builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    // DODANA KONFIGURACJA AUTORYZACJI W SWAGGERZE (przez Bearer token)
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Wprowad� token JWT w formacie: Bearer {tw�j_token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer",
        BearerFormat = "JWT"
    });

    // Wymagaj tokena dla wszystkich endpoint�w
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>() // Pusta lista - token wymagany
        }
    });

    options.OperationFilter<SecurityRequirementsOperationFilter>();
});

builder.Services.AddAutoMapper(typeof(MappingProfile));


// Database context
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions =>
        {
            npgsqlOptions.UseNetTopologySuite(); // do geo
            npgsqlOptions.MigrationsAssembly("H4H.Data");
        }));

// Add logging
builder.Services.AddLogging();


// JWT Authentication 
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true, // Sprawdzaj czy token nie wygas�
            ValidateIssuerSigningKey = true, // Weryfikuj klucz podpisu
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)) // Klucz do weryfikacji
        };
    });

// Rejestracja serwis�w
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IClientService, ClientService>();
builder.Services.AddScoped<ISpecialistService, SpecialistService>();
builder.Services.AddScoped<IGeocoder, Geocoder>();
builder.Services.AddSingleton<FirebaseNotificationService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddHttpClient();


// CORS dla frontendu je�li Flutter debuguje przez przegl�dark�
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter",
        policy => policy
            .AllowAnyOrigin()  // Ka�de �r�d�o
            .AllowAnyMethod()
            .AllowAnyHeader());

});

// Dependency Injection dla Repository
builder.Services.AddScoped<IUserRepository, UserRepository>();

// konfiguracja httpclient dla nominatim
builder.Services.AddHttpClient("Nominatim", client =>
{
    client.BaseAddress = new Uri("https://nominatim.openstreetmap.org/");
    client.DefaultRequestHeaders.UserAgent.ParseAdd("Health4Home/1.0 (contact@health4home.pl)");
    client.DefaultRequestHeaders.Accept.ParseAdd("application/json");
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Rate limiting dla Nominatim (max 1 request na sekund�)
builder.Services.AddSingleton<GeocodingRateLimiter>();

builder.Services.AddScoped<IAdminService, AdminService>();


var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}


// Middleware 
app.UseMiddleware<ErrorHandlingMiddleware>();

app.UseHttpsRedirection();
app.UseCors("AllowFlutter");
app.UseStaticFiles();
app.UseAuthentication();

app.UseAuthorization();
app.MapControllers();

app.Run();




public class SecurityRequirementsOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var authAttributes = (context.MethodInfo.DeclaringType?.GetCustomAttributes(true) ?? Array.Empty<object>())
            .Union(context.MethodInfo.GetCustomAttributes(true))
            .OfType<AuthorizeAttribute>();

        if (authAttributes.Any())
        {
            operation.Security = new List<OpenApiSecurityRequirement>
            {
                new OpenApiSecurityRequirement
                {
                    {
                        new OpenApiSecurityScheme
                        {
                            Reference = new OpenApiReference
                            {
                                Type = ReferenceType.SecurityScheme,
                                Id = "Bearer"
                            }
                        },
                        Array.Empty<string>()
                    }
                }
            };
        }
    }
}
