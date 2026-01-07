using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;

namespace securityindexAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [ApiExplorerSettings(IgnoreApi = true)]
    public class ImportController : ControllerBase
    {
        private readonly SecurityRingDBContext _context;
        private readonly ILogger<ImportController> _logger;

        public ImportController(SecurityRingDBContext context, ILogger<ImportController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 문서 업로드 (파일 + 메타데이터)
        /// </summary>
        [HttpPost("document")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult> UploadDocument(
            [FromForm] string 관제관리번호,
            [FromForm] string 문서명,
            [FromForm] string 문서확장자,
            [FromForm] string? 문서설명,
            [FromForm] string? 문서종류명,
            [FromForm] IFormFile? file)
        {
            try
            {
                _logger.LogInformation($"문서 업로드 요청 시작");
                _logger.LogInformation($"관제관리번호: {관제관리번호}");
                _logger.LogInformation($"문서명: {문서명}");
                _logger.LogInformation($"파일: {file?.FileName ?? "null"}");

                // 유효성 검사
                if (string.IsNullOrWhiteSpace(관제관리번호))
                {
                    _logger.LogWarning("관제관리번호가 비어있음");
                    return BadRequest(new { message = "관제관리번호는 필수입니다." });
                }

                if (file == null || file.Length == 0)
                {
                    _logger.LogWarning("파일이 없음");
                    return BadRequest(new { message = "파일은 필수입니다." });
                }

                if (string.IsNullOrWhiteSpace(문서명))
                {
                    _logger.LogWarning("문서명이 비어있음");
                    return BadRequest(new { message = "문서명은 필수입니다." });
                }

                if (string.IsNullOrWhiteSpace(문서확장자))
                {
                    _logger.LogWarning("문서확장자가 비어있음");
                    return BadRequest(new { message = "문서확장자는 필수입니다." });
                }

                // TODO: FTP 경로 설정 필요
                // FTP 서버 정보 및 경로는 appsettings.json에서 관리하거나 환경변수로 설정
                // 예: ftp://서버주소/documents/{관제관리번호}/{파일명}.{확장자}
                string ftpPath = $"TODO: FTP 경로 설정 필요 - 관제관리번호: {관제관리번호}";

                // 파일 저장 로직 (FTP 업로드)
                // TODO: FTP 업로드 구현
                // await UploadToFtpAsync(file, ftpPath);

                // 문서일련번호 생성 (현재 날짜시간: yyyyMMddHHmmss 형식, 14자리)
                var newSerialNumber = DateTime.Now.ToString("yyyyMMddHHmmss");

                // 문서 정보 DB 저장
                var documentInfo = new 문서관리마스터
                {
                    관제관리번호 = 관제관리번호,
                    문서일련번호 = newSerialNumber,
                    문서명 = 문서명,
                    문서확장자 = 문서확장자,
                    문서설명 = 문서설명 ?? string.Empty,
                    첨부일자 = DateTime.Now, // 현재 날짜/시간
                    첨부자 = string.Empty, // 빈칸으로 저장
                    문서종류 = 문서종류명
                };

                _context.문서관리마스터.Add(documentInfo);
                await _context.SaveChangesAsync();

                _logger.LogInformation($"문서 업로드 완료: 관제관리번호={관제관리번호}, 문서명={문서명}, 문서일련번호={newSerialNumber}");

                return Ok(new
                {
                    message = "문서가 업로드되었습니다.",
                    관제관리번호 = 관제관리번호,
                    문서일련번호 = newSerialNumber,
                    문서명 = 문서명,
                    ftpPath = ftpPath // TODO 경로 표시
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "문서 업로드 중 오류 발생");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        // TODO: FTP 업로드 메서드 구현
        // private async Task UploadToFtpAsync(IFormFile file, string ftpPath)
        // {
        //     // FTP 업로드 로직 구현
        // }
    }
}
