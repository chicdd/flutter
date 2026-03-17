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
        [HttpPost("code/{codeType}")]
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
                        (휴대폰번호, 관제관리번호, 고객관리번호, 상호명, 사용자이름, 원격경계여부, 원격해제여부, 등록일자)
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
        /// 관제 고객 신규 등록
        /// </summary>
        /// <param name="관제관리번호">관제관리번호 (URL 경로)</param>
        /// <param name="request">고객 데이터 (동적 딕셔너리)</param>
        [HttpPost("{관제관리번호}")]
        public async Task<ActionResult> Insert고객저장(string 관제관리번호, [FromBody] Dictionary<string, object> request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                if (request == null || request.Count == 0)
                {
                    return BadRequest(new { message = "저장할 데이터가 없습니다." });
                }

                _logger.LogInformation($"관제 고객 저장 요청: 관제관리번호={관제관리번호}");

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                // 중복 체크
                using (var checkCommand = connection.CreateCommand())
                {
                    checkCommand.CommandText = "SELECT COUNT(*) FROM 관제고객마스터 WHERE 관제관리번호 = @관제관리번호";
                    var checkParam = checkCommand.CreateParameter();
                    checkParam.ParameterName = "@관제관리번호";
                    checkParam.Value = 관제관리번호;
                    checkCommand.Parameters.Add(checkParam);

                    var count = Convert.ToInt32(await checkCommand.ExecuteScalarAsync());
                    if (count > 0)
                    {
                        await connection.CloseAsync();
                        return Conflict(new { message = $"관제관리번호 '{관제관리번호}'는 이미 존재합니다." });
                    }
                }

                // INSERT 쿼리 동적 생성
                var columns = new List<string>();
                var paramNames = new List<string>();

                using var command = connection.CreateCommand();

                int paramIndex = 0;
                foreach (var kvp in request)
                {
                    var columnName = kvp.Key;
                    var value = kvp.Value;
                    var paramName = $"@param{paramIndex}";

                    columns.Add(columnName);
                    paramNames.Add(paramName);

                    var param = command.CreateParameter();
                    param.ParameterName = paramName;

                    if (value == null)
                    {
                        param.Value = DBNull.Value;
                    }
                    else if (value is System.Text.Json.JsonElement jsonElement)
                    {
                        switch (jsonElement.ValueKind)
                        {
                            case System.Text.Json.JsonValueKind.Null:
                                param.Value = DBNull.Value;
                                break;
                            case System.Text.Json.JsonValueKind.String:
                                var strVal = jsonElement.GetString();
                                param.Value = string.IsNullOrEmpty(strVal) ? DBNull.Value : (object)strVal;
                                break;
                            case System.Text.Json.JsonValueKind.Number:
                                if (jsonElement.TryGetInt32(out int intValue))
                                    param.Value = intValue;
                                else if (jsonElement.TryGetInt64(out long longValue))
                                    param.Value = longValue;
                                else if (jsonElement.TryGetDouble(out double doubleValue))
                                    param.Value = doubleValue;
                                else
                                    param.Value = jsonElement.ToString();
                                break;
                            case System.Text.Json.JsonValueKind.True:
                                param.Value = true;
                                break;
                            case System.Text.Json.JsonValueKind.False:
                                param.Value = false;
                                break;
                            default:
                                param.Value = jsonElement.ToString();
                                break;
                        }
                    }
                    else
                    {
                        param.Value = value;
                    }

                    command.Parameters.Add(param);
                    paramIndex++;
                }

                command.CommandText = $@"
                    INSERT INTO 관제고객마스터
                        ({string.Join(", ", columns)})
                    VALUES
                        ({string.Join(", ", paramNames)})";

                _logger.LogDebug($"실행 SQL: {command.CommandText}");

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"관제 고객 저장 완료: 관제관리번호={관제관리번호}");
                return Ok(new { message = "고객이 등록되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"관제 고객 저장 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 부가서비스 추가
        /// </summary>
        [HttpPost("additionalservice")]
        public async Task<ActionResult> InsertAdditionalService([FromBody] 부가서비스요청 request)
        {
            try
            {
                _logger.LogInformation($"부가서비스 추가 요청: 관제관리번호={request.관제관리번호}");

                var query = @"
                    INSERT INTO 부가서비스마스터
                        (관제관리번호, 부가서비스코드, 부가서비스제공코드, 부가서비스일자, 추가메모)
                    VALUES
                        (@관제관리번호, @부가서비스코드, @부가서비스제공코드, @부가서비스일자, @추가메모)";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = request.관제관리번호 ?? (object)DBNull.Value;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@부가서비스코드";
                param2.Value = request.부가서비스코드 ?? (object)DBNull.Value;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@부가서비스제공코드";
                param3.Value = request.부가서비스제공코드 ?? (object)DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@부가서비스일자";
                param4.Value = request.부가서비스일자 ?? (object)DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@추가메모";
                param5.Value = request.추가메모 ?? (object)DBNull.Value;
                command.Parameters.Add(param5);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"부가서비스 추가 완료: 관제관리번호={request.관제관리번호}");
                return StatusCode(201, new { message = "부가서비스가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "부가서비스 추가 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// DVR 연동 정보 추가
        /// </summary>
        [HttpPost("dvr")]
        public async Task<ActionResult> InsertDVR([FromBody] DVR요청 request)
        {
            try
            {
                _logger.LogInformation($"DVR 연동 정보 추가 요청: 관제관리번호={request.관제관리번호}");

                var query = @"
                    INSERT INTO DVR연동마스터
                        (관제관리번호, 접속방식, DVR종류코드, 접속주소, 접속포트, 접속ID, 접속암호, 추가일자, 일련번호)
                    VALUES
                        (@관제관리번호, @접속방식, @DVR종류코드, @접속주소, @접속포트, @접속ID, @접속암호, @추가일자, @일련번호)";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param1 = command.CreateParameter();
                param1.ParameterName = "@관제관리번호";
                param1.Value = request.관제관리번호 ?? (object)DBNull.Value;
                command.Parameters.Add(param1);

                var param2 = command.CreateParameter();
                param2.ParameterName = "@접속방식";
                param2.Value = request.접속방식;
                command.Parameters.Add(param2);

                var param3 = command.CreateParameter();
                param3.ParameterName = "@DVR종류코드";
                param3.Value = request.DVR종류코드 ?? (object)DBNull.Value;
                command.Parameters.Add(param3);

                var param4 = command.CreateParameter();
                param4.ParameterName = "@접속주소";
                param4.Value = request.접속주소 ?? (object)DBNull.Value;
                command.Parameters.Add(param4);

                var param5 = command.CreateParameter();
                param5.ParameterName = "@접속포트";
                param5.Value = request.접속포트 ?? (object)DBNull.Value;
                command.Parameters.Add(param5);

                var param6 = command.CreateParameter();
                param6.ParameterName = "@접속ID";
                param6.Value = request.접속ID ?? (object)DBNull.Value;
                command.Parameters.Add(param6);

                var param7 = command.CreateParameter();
                param7.ParameterName = "@접속암호";
                param7.Value = request.접속암호 ?? (object)DBNull.Value;
                command.Parameters.Add(param7);

                var param8 = command.CreateParameter();
                param8.ParameterName = "@추가일자";
                param8.Value = DateTime.Now;
                command.Parameters.Add(param8);

                var param9 = command.CreateParameter();
                param9.ParameterName = "@일련번호";
                param9.Value = request.일련번호 ?? (object)DBNull.Value;
                command.Parameters.Add(param9);

                await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                _logger.LogInformation($"DVR 연동 정보 추가 완료: 관제관리번호={request.관제관리번호}");
                return StatusCode(201, new { message = "DVR 연동 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "DVR 연동 정보 추가 중 오류 발생");
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
    /// 부가서비스 추가 요청 모델
    /// </summary>
    public class 부가서비스요청
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public string? 부가서비스코드 { get; set; }
        public string? 부가서비스제공코드 { get; set; }
        public DateTime? 부가서비스일자 { get; set; }
        public string? 추가메모 { get; set; }
    }

    /// <summary>
    /// DVR 연동 추가 요청 모델
    /// </summary>
    public class DVR요청
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public int 접속방식 { get; set; } // 0: CS방식, 1: 웹방식
        public string? DVR종류코드 { get; set; }
        public string? 접속주소 { get; set; }
        public string? 접속포트 { get; set; }
        public string? 접속ID { get; set; }
        public string? 접속암호 { get; set; }
        public string? 일련번호 { get; set; }
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
