using Microsoft.EntityFrameworkCore;
using Microsoft.Data.SqlClient;
using securityindexAPI.Data;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

// 영업연결마스터에서 ErpA 연결 문자열 동적 생성
var securityConnectionString = builder.Configuration.GetConnectionString("SecurityConnection");
var erpAConnectionString = "";

try
{
    using (var connection = new SqlConnection(securityConnectionString))
    {
        await connection.OpenAsync();
        var command = new SqlCommand(
            "SELECT TOP 1 서버, DB, ID, 암호 FROM 영업연결마스터 WHERE 사용여부 = '1'",
            connection
        );

        using (var reader = await command.ExecuteReaderAsync())
        {
            if (await reader.ReadAsync())
            {
                var server = reader["서버"]?.ToString();
                var database = reader["DB"]?.ToString();
                var userId = reader["ID"]?.ToString();
                var password = reader["암호"]?.ToString();

                erpAConnectionString = $"Server={server};Database={database};User Id={userId};Password={password};TrustServerCertificate=True;";
                Console.WriteLine($"ErpA 연결 문자열 생성 완료: Server={server}, Database={database}");
            }
            else
            {
                Console.WriteLine("경고: 영업연결마스터에 사용 가능한 연결 정보가 없습니다.");
            }
        }
    }
}
catch (Exception ex)
{
    Console.WriteLine($"ErpA 연결 문자열 생성 중 오류 발생: {ex.Message}");
}

// 데이터베이스 컨텍스트 등록
builder.Services.AddDbContext<SecurityRingDBContext>(options =>
    options.UseSqlServer(securityConnectionString));

builder.Services.AddDbContext<neo_erpaDBContext>(options =>
    options.UseSqlServer(erpAConnectionString));

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
