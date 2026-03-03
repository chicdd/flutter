using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DeleteController : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly ILogger<DeleteController> _logger;

        public DeleteController(SecurityRingDBContext context, ILogger<DeleteController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 코드타입에 따라 동적으로 삭제
        /// </summary>
        /// <param name="codeType">코드타입</param>
        /// <param name="code">삭제할 코드값</param>
        /// <returns>삭제 결과</returns>
        [HttpDelete("{codeType}")]
        public async Task<ActionResult> DeleteCode(string codeType, string code)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(codeType) || string.IsNullOrWhiteSpace(code))
                {
                    return BadRequest(new { message = "코드타입과 코드값은 필수입니다." });
                }

                object? entityToDelete = codeType.ToLower() switch
                {
                    "documenttype" => await _context.문서종류코드마스터.FirstOrDefaultAsync(d => d.문서종류코드 == code),
                    _ => null
                };

                if (entityToDelete == null)
                {
                    return NotFound(new { message = $"코드타입 '{codeType}' 또는 코드값 '{code}'를 찾을 수 없습니다." });
                }

                _context.Remove(entityToDelete);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"코드 삭제 완료: 코드타입={codeType}, 코드값={code}");
                return Ok(new { message = "코드가 삭제되었습니다.", 코드타입 = codeType, 코드값 = code });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"코드 삭제 중 오류 발생: 코드타입={codeType}, 코드값={code}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 부가서비스 삭제
        /// </summary>
        /// <param name="관리id">부가서비스 관리ID</param>
        /// <returns>삭제 결과</returns>
        [HttpDelete("additionalservice/{관리id}")]
        public async Task<ActionResult> DeleteAdditionalService(int 관리id)
        {
            try
            {
                _logger.LogInformation($"부가서비스 삭제 요청: 관리id={관리id}");

                var service = await _context.부가서비스마스터.FirstOrDefaultAsync(s => s.관리id == 관리id);

                if (service == null)
                {
                    return NotFound(new { message = $"관리ID '{관리id}'에 해당하는 부가서비스를 찾을 수 없습니다." });
                }

                _context.부가서비스마스터.Remove(service);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"부가서비스 삭제 완료: 관리id={관리id}");
                return Ok(new { message = "부가서비스가 삭제되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"부가서비스 삭제 중 오류 발생: 관리id={관리id}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// DVR 설치현황 삭제
        /// </summary>
        /// <param name="일련번호">DVR 일련번호</param>
        /// <returns>삭제 결과</returns>
        [HttpDelete("dvr/{일련번호}")]
        public async Task<ActionResult> DeleteDVR(int 일련번호)
        {
            try
            {
                _logger.LogInformation($"DVR 삭제 요청: 일련번호={일련번호}");

                var query = "DELETE FROM DVR연동마스터 WHERE 일련번호 = @일련번호";

                var connection = _context.Database.GetDbConnection();
                await connection.OpenAsync();

                using var command = connection.CreateCommand();
                command.CommandText = query;

                var param = command.CreateParameter();
                param.ParameterName = "@일련번호";
                param.Value = 일련번호;
                command.Parameters.Add(param);

                var rowsAffected = await command.ExecuteNonQueryAsync();
                await connection.CloseAsync();

                if (rowsAffected == 0)
                {
                    return NotFound(new { message = $"일련번호 '{일련번호}'에 해당하는 DVR을 찾을 수 없습니다." });
                }

                _logger.LogInformation($"DVR 삭제 완료: 일련번호={일련번호}");
                return Ok(new { message = "DVR이 삭제되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"DVR 삭제 중 오류 발생: 일련번호={일련번호}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }
    }
}
