using Microsoft.EntityFrameworkCore;
using H4H.Data;
using H4H.Core.Interfaces;
using H4H.Data.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();


// Database context
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        b => b.MigrationsAssembly("H4H.Data")
    ));

// Add logging
builder.Services.AddLogging();

// CORS dla frontendu jeœli Flutter debuguje przez przegl¹darkê
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", 
        policy => policy
            .AllowAnyOrigin()  // Ka¿de Ÿród³o
            .AllowAnyMethod()
            .AllowAnyHeader());
    });
// Abo jeœli Flutter u¿ywa ip to cors nie jest potrzebne i naura

// Dependency Injection dla Repository
builder.Services.AddScoped<IUserRepository, UserRepository>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowFlutter");
app.UseAuthorization();
app.MapControllers();

app.Run();
