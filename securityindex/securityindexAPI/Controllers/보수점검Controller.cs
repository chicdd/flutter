using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api/보수점검")]
    public class 보수점검Controller : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly ILogger<보수점검Controller> _logger;

        public 보수점검Controller(SecurityRingDBContext context, ILogger<보수점검Controller> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 관제관리번호로 보수점검 완료이력 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>보수점검 완료이력 리스트</returns>
        [HttpGet("{관제관리번호}")]
        public async Task<ActionResult> Get보수점검(string 관제관리번호)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    SELECT TOP (1000)
                        [발생자],
                        [점검기준월],
                        [존점검],
                        [키테스트],
                        [키예탁],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [처리자],
                        [고객요청사항]
                    FROM [neosecurity_Ring].[dbo].[보수점검지시마스터]
                    WHERE 관제관리번호 = @관제관리번호 AND 처리완료여부 = '1'
                ";

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 점검리스트 = new List<object>();

                while (await reader.ReadAsync())
                {
                    점검리스트.Add(new
                    {
                        지시자 = reader["발생자"]?.ToString(),
                        점검기준월 = reader["점검기준월"] == DBNull.Value ? null : Convert.ToDateTime(reader["점검기준월"]).ToString("yyyy-MM-dd"),
                        존점검 = reader["존점검"] == DBNull.Value ? false : Convert.ToBoolean(reader["존점검"]),
                        키테스트 = reader["키테스트"] == DBNull.Value ? false : Convert.ToBoolean(reader["키테스트"]),
                        키예탁 = reader["키예탁"] == DBNull.Value ? false : Convert.ToBoolean(reader["키예탁"]),
                        키수량 = reader["키수량"] == DBNull.Value ? 0 : Convert.ToInt32(reader["키수량"]),
                        도면점검 = reader["도면점검"] == DBNull.Value ? false : Convert.ToBoolean(reader["도면점검"]),
                        고객카드 = reader["고객카드"] == DBNull.Value ? false : Convert.ToBoolean(reader["고객카드"]),
                        점검완료자 = reader["처리자"]?.ToString(),
                        고객요청사항 = reader["고객요청사항"]?.ToString()
                    });
                }

                await connection.CloseAsync();

                _logger.LogInformation($"보수점검 완료이력 조회 완료: 관제관리번호={관제관리번호}, 결과수={점검리스트.Count}");
                return Ok(점검리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"보수점검 완료이력 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 보수점검 정보 추가
        /// </summary>
        /// <param name="request">보수점검 정보</param>
        /// <returns>추가 결과</returns>
        [HttpPost]
        public async Task<ActionResult> Post보수점검([FromBody] 보수점검Request request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                var command = connection.CreateCommand();
                command.CommandText = @"
                    INSERT INTO [neosecurity_Ring].[dbo].[보수점검지시마스터]
                    (
                        [관제관리번호],
                        [발생자],
                        [점검기준월],
                        [처리일자],
                        [존점검],
                        [키테스트],
                        [키예탁],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [처리자],
                        [고객요청사항],
                        [처리완료여부]
                    )
                    VALUES
                    (
                        @관제관리번호,
                        @발생자,
                        @점검기준월,
                        @처리일자,
                        @존점검,
                        @키테스트,
                        @키예탁,
                        @키수량,
                        @도면점검,
                        @고객카드,
                        @처리자,
                        @고객요청사항,
                        '1'
                    )
                ";

                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = request.관제관리번호;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@발생자";
                param2.Value = string.IsNullOrWhiteSpace(request.발생자) ? DBNull.Value : request.발생자;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@점검기준월";
                param3.Value = request.점검기준월.HasValue ? request.점검기준월.Value : DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@처리일자";
                param4.Value = request.처리일자.HasValue ? request.처리일자.Value : DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@존점검";
                param5.Value = request.존점검.HasValue ? request.존점검.Value : DBNull.Value;
                command.Parameters.Add(param5);

                var param6 = command.CreateParameter();
                param6.ParameterName = "@키테스트";
                param6.Value = request.키테스트.HasValue ? request.키테스트.Value : DBNull.Value;
                command.Parameters.Add(param6);

                var param7 = command.CreateParameter();
                param7.ParameterName = "@키예탁";
                param7.Value = request.키예탁.HasValue ? request.키예탁.Value : DBNull.Value;
                command.Parameters.Add(param7);

                var param8 = command.CreateParameter();
                param8.ParameterName = "@키수량";
                param8.Value = request.키수량.HasValue ? request.키수량.Value : DBNull.Value;
                command.Parameters.Add(param8);

                var param9 = command.CreateParameter();
                param9.ParameterName = "@도면점검";
                param9.Value = request.도면점검.HasValue ? request.도면점검.Value : DBNull.Value;
                command.Parameters.Add(param9);

                var param10 = command.CreateParameter();
                param10.ParameterName = "@고객카드";
                param10.Value = request.고객카드.HasValue ? request.고객카드.Value : DBNull.Value;
                command.Parameters.Add(param10);

                var param11 = command.CreateParameter();
                param11.ParameterName = "@처리자";
                param11.Value = string.IsNullOrWhiteSpace(request.처리자) ? DBNull.Value : request.처리자;
                command.Parameters.Add(param11);

                var param12 = command.CreateParameter();
                param12.ParameterName = "@고객요청사항";
                param12.Value = string.IsNullOrWhiteSpace(request.고객요청사항) ? DBNull.Value : request.고객요청사항;
                command.Parameters.Add(param12);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"보수점검 추가 완료: 관제관리번호={request.관제관리번호}");
                return StatusCode(201, new { message = "보수점검 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "보수점검 추가 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }
    }

    /// <summary>
    /// 보수점검 추가 요청 모델
    /// </summary>
    public class 보수점검Request
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public string? 발생자 { get; set; }
        public DateTime? 점검기준월 { get; set; }
        public DateTime? 처리일자 { get; set; }
        public bool? 존점검 { get; set; }
        public bool? 키테스트 { get; set; }
        public bool? 키예탁 { get; set; }
        public int? 키수량 { get; set; }
        public bool? 도면점검 { get; set; }
        public bool? 고객카드 { get; set; }
        public string? 처리자 { get; set; }
        public string? 고객요청사항 { get; set; }
    }
}
