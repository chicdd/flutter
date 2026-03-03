using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;

namespace SecurityIndexAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UpdateController : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly ILogger<UpdateController> _logger;

        public UpdateController(SecurityRingDBContext context, ILogger<UpdateController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 기본 고객 정보 수정
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <param name="request">수정할 데이터</param>
        /// <returns>수정 결과</returns>
        [HttpPut("{관제관리번호}")]
        public async Task<ActionResult> UpdateBasicCustomerInfo(string 관제관리번호, [FromBody] Dictionary<string, object> request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                _logger.LogInformation($"기본 고객 정보 수정 요청: 관제관리번호={관제관리번호}");

                // UPDATE 쿼리 동적 생성
                var setClauses = new List<string>();
                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();

                // 관제관리번호 파라미터
                var managerNumberParam = command.CreateParameter();
                managerNumberParam.ParameterName = "@관제관리번호";
                managerNumberParam.Value = 관제관리번호;
                command.Parameters.Add(managerNumberParam);

                int paramIndex = 0;

                foreach (var kvp in request)
                {
                    var columnName = kvp.Key;
                    var value = kvp.Value;

                    var paramName = $"@param{paramIndex}";
                    setClauses.Add($"{columnName} = {paramName}");

                    var param = command.CreateParameter();
                    param.ParameterName = paramName;

                    if (value == null)
                    {
                        param.Value = DBNull.Value;
                    }
                    else if (value is System.Text.Json.JsonElement jsonElement)
                    {
                        // JsonElement 타입 처리
                        switch (jsonElement.ValueKind)
                        {
                            case System.Text.Json.JsonValueKind.Null:
                                param.Value = DBNull.Value;
                                break;
                            case System.Text.Json.JsonValueKind.String:
                                param.Value = jsonElement.GetString();
                                break;
                            case System.Text.Json.JsonValueKind.Number:
                                // 정수인지 실수인지 확인
                                if (jsonElement.TryGetInt32(out int intValue))
                                {
                                    param.Value = intValue;
                                }
                                else if (jsonElement.TryGetInt64(out long longValue))
                                {
                                    param.Value = longValue;
                                }
                                else if (jsonElement.TryGetDouble(out double doubleValue))
                                {
                                    param.Value = doubleValue;
                                }
                                else
                                {
                                    param.Value = jsonElement.ToString();
                                }
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
                    else if (value is bool boolValue)
                    {
                        param.Value = boolValue;
                    }
                    else if (value is string stringValue)
                    {
                        param.Value = stringValue;
                    }
                    else if (value is int || value is long || value is double || value is decimal)
                    {
                        param.Value = value;
                    }
                    else
                    {
                        param.Value = value.ToString();
                    }

                    command.Parameters.Add(param);
                    paramIndex++;
                }

                if (setClauses.Count == 0)
                {
                    await connection.CloseAsync();
                    return BadRequest(new { message = "수정할 데이터가 없습니다." });
                }

                var query = $@"
                    UPDATE 관제고객마스터
                    SET {string.Join(", ", setClauses)}
                    WHERE 관제관리번호 = @관제관리번호";

                command.CommandText = query;

                _logger.LogDebug($"실행 SQL: {query}");

                var rowsAffected = await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                if (rowsAffected > 0)
                {
                    _logger.LogInformation($"기본 고객 정보 수정 완료: 관제관리번호={관제관리번호}");
                    return Ok(new { message = "기본 고객 정보가 수정되었습니다." });
                }
                else
                {
                    _logger.LogWarning($"수정할 고객을 찾을 수 없음: 관제관리번호={관제관리번호}");
                    return NotFound(new { message = "수정할 고객을 찾을 수 없습니다." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"기본 고객 정보 수정 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 약도 이미지 업데이트
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <param name="request">약도 데이터 (Base64 인코딩된 이미지)</param>
        /// <returns>수정 결과</returns>
        [HttpPut("약도업데이트/{관제관리번호}")]
        public async Task<ActionResult> UpdateMapDiagram(string 관제관리번호, [FromBody] Dictionary<string, object> request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                if (!request.ContainsKey("약도데이터"))
                {
                    return BadRequest(new { message = "약도데이터는 필수입니다." });
                }

                _logger.LogInformation($"약도 이미지 업데이트 요청: 관제관리번호={관제관리번호}");

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();

                // Base64 문자열을 바이트 배열로 변환
                byte[] imageBytes;
                var imageData = request["약도데이터"];

                if (imageData is System.Text.Json.JsonElement jsonElement)
                {
                    var base64String = jsonElement.GetString();
                    if (string.IsNullOrEmpty(base64String))
                    {
                        await connection.CloseAsync();
                        return BadRequest(new { message = "약도데이터가 비어있습니다." });
                    }
                    imageBytes = Convert.FromBase64String(base64String);
                }
                else if (imageData is string stringValue)
                {
                    imageBytes = Convert.FromBase64String(stringValue);
                }
                else
                {
                    await connection.CloseAsync();
                    return BadRequest(new { message = "약도데이터 형식이 올바르지 않습니다." });
                }

                // UPDATE 쿼리
                var query = @"
                    UPDATE 약도마스터
                    SET 약도데이터 = @약도데이터,
                        등록일자 = GETDATE()
                    WHERE 관제관리번호 = @관제관리번호";

                command.CommandText = query;

                var managerNumberParam = command.CreateParameter();
                managerNumberParam.ParameterName = "@관제관리번호";
                managerNumberParam.Value = 관제관리번호;
                command.Parameters.Add(managerNumberParam);

                var imageParam = command.CreateParameter();
                imageParam.ParameterName = "@약도데이터";
                imageParam.Value = imageBytes;
                command.Parameters.Add(imageParam);

                var rowsAffected = await command.ExecuteNonQueryAsync();

                // 업데이트된 행이 없으면 INSERT 시도
                if (rowsAffected == 0)
                {
                    _logger.LogInformation($"약도 데이터 없음, 새로 삽입 시도: 관제관리번호={관제관리번호}");

                    command.Parameters.Clear();
                    command.CommandText = @"
                        INSERT INTO 약도마스터 (관제관리번호, 약도데이터, 등록일자, 순번, DATA구분코드)
                        VALUES (@관제관리번호, @약도데이터, GETDATE(), '1', '1')";

                    command.Parameters.Add(managerNumberParam);
                    command.Parameters.Add(imageParam);

                    rowsAffected = await command.ExecuteNonQueryAsync();
                }

                await connection.CloseAsync();

                if (rowsAffected > 0)
                {
                    _logger.LogInformation($"약도 이미지 업데이트 완료: 관제관리번호={관제관리번호}, 이미지 크기={imageBytes.Length} bytes");
                    return Ok(new { message = "약도 이미지가 업데이트되었습니다." });
                }
                else
                {
                    _logger.LogWarning($"약도 업데이트 실패: 관제관리번호={관제관리번호}");
                    return StatusCode(500, new { message = "약도 이미지 업데이트에 실패했습니다." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"약도 이미지 업데이트 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 도면 이미지 업데이트
        /// </summary>
        /// <param name="관제관리번호">관제관리번호</param>
        /// <param name="request">도면 데이터 (Base64 인코딩된 이미지)</param>
        /// <returns>수정 결과</returns>
        [HttpPut("도면업데이트/{관제관리번호}")]
        public async Task<ActionResult> UpdateBlueprint(string 관제관리번호, [FromBody] Dictionary<string, object> request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                if (!request.ContainsKey("도면데이터"))
                {
                    return BadRequest(new { message = "도면데이터는 필수입니다." });
                }

                if (!request.ContainsKey("도면타입"))
                {
                    return BadRequest(new { message = "도면타입은 필수입니다." });
                }

                _logger.LogInformation($"도면 이미지 업데이트 요청: 관제관리번호={관제관리번호}");

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();

                // Base64 문자열을 바이트 배열로 변환
                byte[] imageBytes;
                var imageData = request["도면데이터"];

                if (imageData is System.Text.Json.JsonElement jsonElement)
                {
                    var base64String = jsonElement.GetString();
                    if (string.IsNullOrEmpty(base64String))
                    {
                        await connection.CloseAsync();
                        return BadRequest(new { message = "도면데이터가 비어있습니다." });
                    }
                    imageBytes = Convert.FromBase64String(base64String);
                }
                else if (imageData is string stringValue)
                {
                    imageBytes = Convert.FromBase64String(stringValue);
                }
                else
                {
                    await connection.CloseAsync();
                    return BadRequest(new { message = "도면데이터 형식이 올바르지 않습니다." });
                }

                // 도면 타입 확인 (1: 도면마스터, 2: 도면마스터2)
                var blueprintTypeData = request["도면타입"];
                string blueprintType = "1";

                if (blueprintTypeData is System.Text.Json.JsonElement blueprintTypeElement)
                {
                    blueprintType = blueprintTypeElement.GetString() ?? "1";
                }
                else if (blueprintTypeData is string blueprintTypeString)
                {
                    blueprintType = blueprintTypeString;
                }

                // 테이블 이름 결정
                string tableName = blueprintType == "2" ? "도면마스터2" : "도면마스터";

                // UPDATE 쿼리
                var query = $@"
                    UPDATE {tableName}
                    SET 도면데이터 = @도면데이터,
                        등록일자 = GETDATE()
                    WHERE 관제관리번호 = @관제관리번호";

                command.CommandText = query;

                var managerNumberParam = command.CreateParameter();
                managerNumberParam.ParameterName = "@관제관리번호";
                managerNumberParam.Value = 관제관리번호;
                command.Parameters.Add(managerNumberParam);

                var imageParam = command.CreateParameter();
                imageParam.ParameterName = "@도면데이터";
                imageParam.Value = imageBytes;
                command.Parameters.Add(imageParam);

                var rowsAffected = await command.ExecuteNonQueryAsync();

                // 업데이트된 행이 없으면 INSERT 시도
                if (rowsAffected == 0)
                {
                    _logger.LogInformation($"도면 데이터 없음, 새로 삽입 시도: 관제관리번호={관제관리번호}, 테이블={tableName}");

                    command.Parameters.Clear();
                    command.CommandText = $@"
                        INSERT INTO {tableName} (관제관리번호, 도면데이터, 등록일자, DATA구분코드)
                        VALUES (@관제관리번호, @도면데이터, GETDATE(), '{blueprintType}', '1')";

                    command.Parameters.Add(managerNumberParam);
                    command.Parameters.Add(imageParam);

                    rowsAffected = await command.ExecuteNonQueryAsync();
                }

                await connection.CloseAsync();

                if (rowsAffected > 0)
                {
                    _logger.LogInformation($"도면 이미지 업데이트 완료: 관제관리번호={관제관리번호}, 테이블={tableName}, 이미지 크기={imageBytes.Length} bytes");
                    return Ok(new { message = "도면 이미지가 업데이트되었습니다." });
                }
                else
                {
                    _logger.LogWarning($"도면 업데이트 실패: 관제관리번호={관제관리번호}, 테이블={tableName}");
                    return StatusCode(500, new { message = "도면 이미지 업데이트에 실패했습니다." });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"도면 이미지 업데이트 중 오류 발생: 관제관리번호={관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 주간휴일설정 저장 (DELETE 후 INSERT)
        /// </summary>
        /// <param name="request">휴일주간 저장 요청</param>
        /// <returns>저장 결과</returns>
        [HttpPost("holiday")]
        public async Task<ActionResult> UpdateHolidayWeek([FromBody] HolidayWeekRequest request)
        {
            try
            {
                _logger.LogInformation($"주간휴일설정 저장 요청: 관제관리번호={request.관제관리번호}, 휴일코드수={request.휴일주간코드목록?.Count ?? 0}");

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var transaction = connection.BeginTransaction();

                try
                {
                    // 1. 기존 데이터 삭제
                    var deleteQuery = "DELETE FROM 관제고객휴일주간 WHERE 관제관리번호 = @관제관리번호";
                    using (var deleteCommand = connection.CreateCommand())
                    {
                        deleteCommand.CommandText = deleteQuery;
                        deleteCommand.Transaction = transaction;

                        var deleteParam = deleteCommand.CreateParameter();
                        deleteParam.ParameterName = "@관제관리번호";
                        deleteParam.Value = request.관제관리번호;
                        deleteCommand.Parameters.Add(deleteParam);

                        await deleteCommand.ExecuteNonQueryAsync();
                    }

                    // 2. 새 데이터 삽입
                    if (request.휴일주간코드목록 != null && request.휴일주간코드목록.Count > 0)
                    {
                        var insertQuery = @"
                            INSERT INTO 관제고객휴일주간 (관제관리번호, 휴일주간코드)
                            VALUES (@관제관리번호, @휴일주간코드)";

                        foreach (var holidayCode in request.휴일주간코드목록)
                        {
                            using var insertCommand = connection.CreateCommand();
                            insertCommand.CommandText = insertQuery;
                            insertCommand.Transaction = transaction;

                            var param1 = insertCommand.CreateParameter();
                            param1.ParameterName = "@관제관리번호";
                            param1.Value = request.관제관리번호;
                            insertCommand.Parameters.Add(param1);

                            var param2 = insertCommand.CreateParameter();
                            param2.ParameterName = "@휴일주간코드";
                            param2.Value = holidayCode;
                            insertCommand.Parameters.Add(param2);

                            await insertCommand.ExecuteNonQueryAsync();
                        }
                    }

                    await transaction.CommitAsync();
                    await connection.CloseAsync();

                    _logger.LogInformation($"주간휴일설정 저장 완료: 관제관리번호={request.관제관리번호}");
                    return Ok(new { message = "주간휴일설정이 저장되었습니다." });
                }
                catch (Exception)
                {
                    await transaction.RollbackAsync();
                    await connection.CloseAsync();
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"주간휴일설정 저장 중 오류 발생: 관제관리번호={request.관제관리번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }
    }

    /// <summary>
    /// 휴일주간 저장 요청 모델
    /// </summary>
    public class HolidayWeekRequest
    {
        public string 관제관리번호 { get; set; } = string.Empty;
        public List<string>? 휴일주간코드목록 { get; set; }
    }
}
