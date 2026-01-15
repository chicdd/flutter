using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class InsertController : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly ILogger<InsertController> _logger;

        public InsertController(SecurityRingDBContext context, ILogger<InsertController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 코드타입에 따라 동적으로 추가
        /// </summary>
        /// <param name="codeType">코드타입</param>
        /// <param name="code">추가할 코드값</param>
        /// <param name="codeName">추가할 코드명</param>
        /// <returns>추가 결과</returns>
        [HttpPost("{codeType}")]
        public async Task<ActionResult> InsertCode(string codeType, [FromBody] CodeRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(codeType))
                {
                    return BadRequest(new { message = "코드타입은 필수입니다." });
                }

                if (string.IsNullOrWhiteSpace(request.code))
                {
                    return BadRequest(new { message = "코드값은 필수입니다." });
                }

                if (string.IsNullOrWhiteSpace(request.codeName))
                {
                    return BadRequest(new { message = "코드명은 필수입니다." });
                }

                string tableName = "";
                string codeColumn = "";
                string nameColumn = "";

                switch (codeType.ToLower())
                {
                    case "documenttype":
                        // 코드는 3자리여야 함
                        if (request.code.Length != 3)
                        {
                            return BadRequest(new { message = "문서종류코드는 3자리여야 합니다." });
                        }
                        tableName = "문서종류코드마스터";
                        codeColumn = "문서종류코드";
                        nameColumn = "문서종류코드명";
                        break;

                    default:
                        return BadRequest(new { message = $"지원하지 않는 코드타입입니다: {codeType}" });
                }

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                // 중복 체크
                var checkQuery = $"SELECT COUNT(*) FROM {tableName} WHERE {codeColumn} = @code";
                using (var checkCommand = connection.CreateCommand())
                {
                    checkCommand.CommandText = checkQuery;

                    var checkParam = checkCommand.CreateParameter();
                    checkParam.ParameterName = "@code";
                    checkParam.Value = request.code;
                    checkCommand.Parameters.Add(checkParam);

                    var count = Convert.ToInt32(await checkCommand.ExecuteScalarAsync());
                    if (count > 0)
                    {
                        await connection.CloseAsync();
                        return Conflict(new { message = $"코드 '{request.code}'는 이미 존재합니다." });
                    }
                }

                // INSERT 실행
                var insertQuery = $"INSERT INTO {tableName} ({codeColumn}, {nameColumn}) VALUES (@code, @codeName)";
                using var insertCommand = connection.CreateCommand();
                insertCommand.CommandText = insertQuery;

                var codeParam = insertCommand.CreateParameter();
                codeParam.ParameterName = "@code";
                codeParam.Value = request.code;
                insertCommand.Parameters.Add(codeParam);

                var nameParam = insertCommand.CreateParameter();
                nameParam.ParameterName = "@codeName";
                nameParam.Value = request.codeName;
                insertCommand.Parameters.Add(nameParam);

                await insertCommand.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"코드 추가 완료: 코드타입={codeType}, 코드값={request.code}, 코드명={request.codeName}");
                return StatusCode(201, new { message = "코드가 추가되었습니다.", 코드타입 = codeType, 코드값 = request.code, 코드명 = request.codeName });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"코드 추가 중 오류 발생: 코드타입={codeType}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 스마트폰 앱 인증 정보 추가
        /// </summary>
        [HttpPost("auth")]
        public async Task<ActionResult> InsertAuth([FromBody] 스마트정보조회마스터 request)
        {
            try
            {
                _logger.LogInformation($"인증 정보 추가 요청: 휴대폰번호={request.관제관리번호}");

                var query = @"
                    INSERT INTO 스마트정보조회마스터
                        (휴대폰번호, 관제관리번호, 영업관리번호, 상호명, 사용자이름, 원격경계여부, 원격해제여부, 등록일자)
                    VALUES
                        (@휴대폰번호, @관제관리번호, @영업관리번호, @상호명, @사용자이름, @원격경계여부, @원격해제여부, @등록일자)";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param1 = command.CreateParameter();
                param1.ParameterName = "@휴대폰번호";
                param1.Value = request.휴대폰번호 ?? (object)DBNull.Value;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@관제관리번호";
                param2.Value = request.관제관리번호 ?? (object)DBNull.Value;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@영업관리번호";
                param3.Value = request.영업관리번호 ?? (object)DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@상호명";
                param4.Value = request.상호명 ?? (object)DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@사용자이름";
                param5.Value = request.사용자이름 ?? (object)DBNull.Value;
                command.Parameters.Add(param5);

                var param6 = command.CreateParameter();
                param6.ParameterName = "@원격경계여부";
                param6.Value = request.원격경계여부;
                command.Parameters.Add(param6);

                var param7 = command.CreateParameter();
                param7.ParameterName = "@원격해제여부";
                param7.Value = request.원격해제여부;
                command.Parameters.Add(param7);

                var param8 = command.CreateParameter();
                param8.ParameterName = "@등록일자";
                param8.Value = DateTime.Now;
                command.Parameters.Add(param8);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"인증 정보 추가 완료: 휴대폰번호={request.휴대폰번호}");
                return StatusCode(201, new { message = "인증 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "인증 정보 추가 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// AS접수 정보 추가
        /// </summary>
        [HttpPost("assummit")]
        public async Task<ActionResult> InsertAS접수([FromBody] AS접수요청 request)
        {
            try
            {
                _logger.LogInformation($"AS접수 정보 추가 요청: 관제관리번호={request.관제관리번호}");

                var query = @"
                    INSERT INTO AS접수마스터
                        (관제관리번호, 고객이름, 고객연락처, 요청일자, 요청시간, 요청제목, 접수일자, 접수시간, 담당구역, 처리여부, 입력자, 세부내용)
                    VALUES
                        (@관제관리번호, @고객이름, @고객연락처, @요청일자, @요청시간, @요청제목, @접수일자, @접수시간, @담당구역, @처리여부, @입력자, @세부내용)";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = request.관제관리번호 ?? (object)DBNull.Value;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@고객이름";
                param2.Value = request.고객이름 ?? (object)DBNull.Value;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@고객연락처";
                param3.Value = request.고객연락처 ?? (object)DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@요청일자";
                param4.Value = request.요청일자 ?? (object)DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@요청시간";
                param5.Value = request.요청시간 ?? (object)DBNull.Value;
                command.Parameters.Add(param5);

                var param6 = command.CreateParameter();
                param6.ParameterName = "@요청제목";
                param6.Value = request.요청제목 ?? (object)DBNull.Value;
                command.Parameters.Add(param6);

                var param7 = command.CreateParameter();
                param7.ParameterName = "@접수일자";
                param7.Value = request.접수일자 ?? (object)DBNull.Value;
                command.Parameters.Add(param7);

                var param8 = command.CreateParameter();
                param8.ParameterName = "@접수시간";
                param8.Value = request.접수시간 ?? (object)DBNull.Value;
                command.Parameters.Add(param8);

                var param9 = command.CreateParameter();
                param9.ParameterName = "@담당구역";
                param9.Value = request.담당구역 ?? (object)DBNull.Value;
                command.Parameters.Add(param9);

                var param10 = command.CreateParameter();
                param10.ParameterName = "@처리여부";
                param10.Value = "미처리";
                command.Parameters.Add(param10);

                var param11 = command.CreateParameter();
                param11.ParameterName = "@입력자";
                param11.Value = request.입력자 ?? (object)DBNull.Value;
                command.Parameters.Add(param11);

                var param12 = command.CreateParameter();
                param12.ParameterName = "@세부내용";
                param12.Value = request.세부내용 ?? (object)DBNull.Value;
                command.Parameters.Add(param12);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"AS접수 정보 추가 완료: 관제관리번호={request.관제관리번호}");
                return StatusCode(201, new { message = "AS접수 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "AS접수 정보 추가 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }
    }

    /// <summary>
    /// 코드 추가 요청 모델
    /// </summary>
    public class CodeRequest
    {
        public string code { get; set; } = string.Empty;
        public string codeName { get; set; } = string.Empty;
    }

    /// <summary>
    /// AS접수 추가 요청 모델
    /// </summary>
    public class AS접수요청
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public string? 고객이름 { get; set; }
        public string? 고객연락처 { get; set; }
        public DateTime? 요청일자 { get; set; }
        public string? 요청시간 { get; set; }
        public DateTime? 접수일자 { get; set; }
        public string? 접수시간 { get; set; }
        public string? 요청제목 { get; set; }
        public string? 담당구역 { get; set; }
        public string? 입력자 { get; set; }
        public string? 세부내용 { get; set; }
    }

    /// <summary>
    /// 인증 정보 추가 요청 모델
    /// </summary>
    //public class AuthRequest
    //{
    //    public string phoneNumber { get; set; } = string.Empty;
    //    public string controlManagementNumber { get; set; } = string.Empty;
    //    public string? erpCusNumber { get; set; }
    //    public string? businessName { get; set; }
    //    public string? userName { get; set; }
    //    public bool remoteGuardAllowed { get; set; }
    //    public bool remoteReleaseAllowed { get; set; }
    //}
}
