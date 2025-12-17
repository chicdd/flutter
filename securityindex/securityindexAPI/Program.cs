using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

// 데이터베이스 컨텍스트 등록
builder.Services.AddDbContext<SecurityRingDBContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("SecurityConnection")));

builder.Services.AddDbContext<neo_erpaDBContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ErpAConnection")));

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
