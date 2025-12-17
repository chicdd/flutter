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
    }
}
