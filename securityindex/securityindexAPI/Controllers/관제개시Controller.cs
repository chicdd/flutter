using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api/관제개시")]
    public class 관제개시Controller : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly ILogger<관제개시Controller> _logger;

        public 관제개시Controller(SecurityRingDBContext context, ILogger<관제개시Controller> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 관제관리번호로 관제개시 정보 조회
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <returns>관제개시 정보 리스트</returns>
        [HttpGet("{관제관리번호}")]
        public async Task<ActionResult> Get관제개시(string 관제관리번호)
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
                        [경비개시일자],
                        [존점검결과],
                        [키테스트],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [점검자],
                        [관제확인자],
                        [설치공사자],
                        [키인수자],
                        [비고사항]
                    FROM [neosecurity_Ring].[dbo].[관제개시마스터]
                    WHERE 관제관리번호 = @관제관리번호
                ";

                var param = command.CreateParameter();
                param.ParameterName = "@관제관리번호";
                param.Value = 관제관리번호;
                command.Parameters.Add(param);

                using var reader = await command.ExecuteReaderAsync();
                var 개시리스트 = new List<object>();

                while (await reader.ReadAsync())
                {
                    개시리스트.Add(new
                    {
                        개시 = reader["경비개시일자"] == DBNull.Value ? null : Convert.ToDateTime(reader["경비개시일자"]).ToString("yyyy-MM-dd"),
                        ZONECK = reader["존점검결과"] == DBNull.Value ? false : Convert.ToBoolean(reader["존점검결과"]),
                        KEYCK = reader["키테스트"] == DBNull.Value ? false : Convert.ToBoolean(reader["키테스트"]),
                        KEYS = reader["키수량"] == DBNull.Value ? 0 : Convert.ToInt32(reader["키수량"]),
                        도면 = reader["도면점검"] == DBNull.Value ? false : Convert.ToBoolean(reader["도면점검"]),
                        고객카드 = reader["고객카드"] == DBNull.Value ? false : Convert.ToBoolean(reader["고객카드"]),
                        개시처리자 = reader["점검자"]?.ToString(),
                        관제확인자 = reader["관제확인자"]?.ToString(),
                        설치공사자 = reader["설치공사자"]?.ToString(),
                        키인수자 = reader["키인수자"]?.ToString(),
                        비고 = reader["비고사항"]?.ToString()
                    });
                }

                await connection.CloseAsync();

                _logger.LogInformation($"관제개시 조회 완료: 관제관리번호={관제관리번호}, 결과수={개시리스트.Count}");
                return Ok(개시리스트);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"관제개시 조회 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 관제개시 정보 추가
        /// </summary>
        /// <param name="request">관제개시 정보</param>
        /// <returns>추가 결과</returns>
        [HttpPost]
        public async Task<ActionResult> Post관제개시([FromBody] 관제개시Request request)
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
                    INSERT INTO [neosecurity_Ring].[dbo].[관제개시마스터]
                    (
                        [관제관리번호],
                        [경비개시일자],
                        [존점검결과],
                        [키테스트],
                        [키수량],
                        [도면점검],
                        [고객카드],
                        [점검자],
                        [관제확인자],
                        [설치공사자],
                        [키인수자],
                        [비고사항]
                    )
                    VALUES
                    (
                        @관제관리번호,
                        @경비개시일자,
                        @존점검결과,
                        @키테스트,
                        @키수량,
                        @도면점검,
                        @고객카드,
                        @점검자,
                        @관제확인자,
                        @설치공사자,
                        @키인수자,
                        @비고사항
                    )
                ";

                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = request.관제관리번호;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@경비개시일자";
                param2.Value = request.경비개시일자.HasValue ? request.경비개시일자.Value : DBNull.Value;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@존점검결과";
                param3.Value = request.존점검결과.HasValue ? request.존점검결과.Value : DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@키테스트";
                param4.Value = request.키테스트.HasValue ? request.키테스트.Value : DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@키수량";
                param5.Value = request.키수량.HasValue ? request.키수량.Value : DBNull.Value;
                command.Parameters.Add(param5);

                var param6 = command.CreateParameter();
                param6.ParameterName = "@도면점검";
                param6.Value = request.도면점검.HasValue ? request.도면점검.Value : DBNull.Value;
                command.Parameters.Add(param6);

                var param7 = command.CreateParameter();
                param7.ParameterName = "@고객카드";
                param7.Value = request.고객카드.HasValue ? request.고객카드.Value : DBNull.Value;
                command.Parameters.Add(param7);

                var param8 = command.CreateParameter();
                param8.ParameterName = "@점검자";
                param8.Value = string.IsNullOrWhiteSpace(request.점검자) ? DBNull.Value : request.점검자;
                command.Parameters.Add(param8);

                var param9 = command.CreateParameter();
                param9.ParameterName = "@관제확인자";
                param9.Value = string.IsNullOrWhiteSpace(request.관제확인자) ? DBNull.Value : request.관제확인자;
                command.Parameters.Add(param9);

                var param10 = command.CreateParameter();
                param10.ParameterName = "@설치공사자";
                param10.Value = string.IsNullOrWhiteSpace(request.설치공사자) ? DBNull.Value : request.설치공사자;
                command.Parameters.Add(param10);

                var param11 = command.CreateParameter();
                param11.ParameterName = "@키인수자";
                param11.Value = string.IsNullOrWhiteSpace(request.키인수자) ? DBNull.Value : request.키인수자;
                command.Parameters.Add(param11);

                var param12 = command.CreateParameter();
                param12.ParameterName = "@비고사항";
                param12.Value = string.IsNullOrWhiteSpace(request.비고사항) ? DBNull.Value : request.비고사항;
                command.Parameters.Add(param12);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"관제개시 추가 완료: 관제관리번호={request.관제관리번호}");
                return StatusCode(201, new { message = "관제개시 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "관제개시 추가 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }
    }

    /// <summary>
    /// 관제개시 추가 요청 모델
    /// </summary>
    public class 관제개시Request
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public DateTime? 경비개시일자 { get; set; }
        public bool? 존점검결과 { get; set; }
        public bool? 키테스트 { get; set; }
        public int? 키수량 { get; set; }
        public bool? 도면점검 { get; set; }
        public bool? 고객카드 { get; set; }
        public string? 점검자 { get; set; }
        public string? 관제확인자 { get; set; }
        public string? 설치공사자 { get; set; }
        public string? 키인수자 { get; set; }
        public string? 비고사항 { get; set; }
    }
}
