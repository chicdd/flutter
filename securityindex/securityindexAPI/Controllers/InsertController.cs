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

                object? entityToAdd = null;
                object? existingEntity = null;

                switch (codeType.ToLower())
                {
                    case "documenttype":
                        // 코드는 3자리여야 함
                        if (request.code.Length != 3)
                        {
                            return BadRequest(new { message = "문서종류코드는 3자리여야 합니다." });
                        }

                        // 중복 체크
                        existingEntity = await _context.문서종류코드마스터
                            .FirstOrDefaultAsync(d => d.문서종류코드 == request.code);

                        if (existingEntity != null)
                        {
                            return Conflict(new { message = $"코드 '{request.code}'는 이미 존재합니다." });
                        }

                        entityToAdd = new 문서종류코드모델
                        {
                            문서종류코드 = request.code,
                            문서종류코드명 = request.codeName
                        };
                        break;

                    default:
                        return BadRequest(new { message = $"지원하지 않는 코드타입입니다: {codeType}" });
                }

                if (entityToAdd == null)
                {
                    return BadRequest(new { message = "추가할 데이터를 생성할 수 없습니다." });
                }

                _context.Add(entityToAdd);
                await _context.SaveChangesAsync();

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

                // 새 인증 정보 생성
                var authInfo = new 스마트정보조회마스터
                {
                    휴대폰번호 = request.휴대폰번호,
                    관제관리번호 = request.관제관리번호,
                    영업관리번호 = request.영업관리번호,
                    상호명 = request.상호명,
                    사용자이름 = request.사용자이름,
                    원격경계여부 = request.원격경계여부,
                    원격해제여부 = request.원격해제여부,
                    등록일자 = DateTime.Now
                };

                _context.스마트정보조회마스터.Add(authInfo);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"인증 정보 추가 완료: 휴대폰번호={request.휴대폰번호}");
                return StatusCode(201, new { message = "인증 정보가 추가되었습니다." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "인증 정보 추가 중 오류 발생");
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
