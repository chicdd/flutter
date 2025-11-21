using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using securityindexAPI.Data;
using securityindexAPI.Models;

namespace securityindexAPI.Controllers
{
    /// <summary>
    /// 드롭다운 데이터를 제공하는 컨트롤러
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class DropdownController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<DropdownController> _logger;

        public DropdownController(ApplicationDbContext context, ILogger<DropdownController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// 코드 유형에 따라 드롭다운 데이터를 반환
        /// </summary>
        /// <param name="codeType">코드 유형 (managementArea, operationArea, businessType, userCode, policeStation, policeDistrict, usageLine, serviceType, mainSystem, subSystem, miSettings)</param>
        /// <returns>코드 데이터 리스트</returns>
        [HttpGet("{codeType}")]
        public async Task<ActionResult<IEnumerable<CodeData>>> GetDropdownData(string codeType)
        {
            try
            {
                List<CodeData> result = new List<CodeData>();

                switch (codeType.ToLower())
                {
                    case "managementarea": // 관리구역
                        result = await _context.관리구역코드
                            .Select(x => new CodeData
                            {
                                Code = x.관리구역코드,
                                Name = x.관리구역코드명
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "operationarea": // 출동권역
                        result = await _context.출동권역코드
                            .Select(x => new CodeData
                            {
                                Code = x.출동권역코드,
                                Name = x.출동권역코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "businesstype": // 업종코드
                        result = await _context.업종대코드
                            .Select(x => new CodeData
                            {
                                Code = x.업종대코드,
                                Name = x.업종대코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "policestation": // 관할경찰서
                        result = await _context.경찰서코드
                            .Select(x => new CodeData
                            {
                                Code = x.경찰서코드,
                                Name = x.경찰서코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "policedistrict": // 관할지구대
                        result = await _context.지구대코드
                            .Select(x => new CodeData
                            {
                                Code = x.지구대코드,
                                Name = x.지구대코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "usageline": // 사용회선
                        result = await _context.사용회선종류
                            .Select(x => new CodeData
                            {
                                Code = x.사용회선종류,
                                Name = x.사용회선종류명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "servicetype": // 서비스종류
                        result = await _context.서비스종류코드
                            .Select(x => new CodeData
                            {
                                Code = x.서비스종류코드,
                                Name = x.서비스종류코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "customerstatus": // 관제고객상태
                        result = await _context.관제고객상태코드
                            .Select(x => new CodeData
                            {
                                Code = x.관제고객상태코드,
                                Name = x.관제고객상태코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "mainsystem": // 주장치종류
                        result = await _context.기기종류코드
                            .Select(x => new CodeData
                            {
                                Code = x.기기종류코드,
                                Name = x.기기종류명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "subsystem": // 주장치분류
                        result = await _context.미경계분류코드
                            .Select(x => new CodeData
                            {
                                Code = x.미경계분류코드,
                                Name = x.미경계분류코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "vehiclecode": // 차량코드
                        result = await _context.차량코드
                            .Select(x => new CodeData
                            {
                                Code = x.차량코드,
                                Name = x.차량코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "misettings": // 미경계설정
                        result = await _context.미경계종류코드
                            .Select(x => new CodeData
                            {
                                Code = x.미경계종류코드,
                                Name = x.미경계종류코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "companytype": // 회사구분
                        result = await _context.회사구분코드
                            .Select(x => new CodeData
                            {
                                Code = x.회사구분코드,
                                Name = x.회사구분코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    case "branchtype": // 지사구분
                        result = await _context.지사구분코드
                            .Select(x => new CodeData
                            {
                                Code = x.지사구분코드,
                                Name = x.지사구분코드명,
                            })
                            .OrderBy(x => x.Code)
                            .ToListAsync();
                        break;

                    default:
                        return BadRequest(new { message = $"지원하지 않는 코드 유형입니다: {codeType}" });
                }

                _logger.LogInformation($"드롭다운 데이터 조회: {codeType}, 결과 수: {result.Count}");
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"드롭다운 데이터 조회 중 오류 발생: {codeType}");
                return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
            }
        }

        /// <summary>
        /// 모든 드롭다운 데이터를 한 번에 반환
        /// </summary>
        /// <returns>모든 코드 데이터</returns>
        //[HttpGet("all")]
        //public async Task<ActionResult<Dictionary<string, List<CodeData>>>> GetAllDropdownData()
        //{
        //    try
        //    {
        //        var result = new Dictionary<string, List<CodeData>>();

        //        // 모든 코드 유형을 순회하며 데이터 수집
        //        var codeTypes = new[]
        //        {
        //            "managementarea", "operationarea", "businesstype", "vehiclecode",
        //            "policestation", "policedistrict", "usageline", "servicetype",
        //            "customerstatus", "mainsystem", "subsystem", "misettings"
        //        };

        //        foreach (var codeType in codeTypes)
        //        {
        //            var response = await GetDropdownData(codeType);
        //            if (response.Result is OkObjectResult okResult)
        //            {
        //                result[codeType] = (List<CodeData>)okResult.Value!;
        //            }
        //        }

        //        return Ok(result);
        //    }
        //    catch (Exception ex)
        //    {
        //        _logger.LogError(ex, "전체 드롭다운 데이터 조회 중 오류 발생");
        //        return StatusCode(500, new { message = "서버 오류가 발생했습니다.", error = ex.Message });
        //    }
        //}
    }

    /// <summary>
    /// 드롭다운 코드 데이터 모델
    /// </summary>
    public class CodeData
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
    }
}
