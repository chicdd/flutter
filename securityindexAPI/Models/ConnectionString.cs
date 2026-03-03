using securityindexAPI.Controllers;

namespace securityindexAPI.Models
{
    public class ConnectionString
    {
        public static List<OpeningCompany> GetCompanies()
        {
            return new List<OpeningCompany>
            {
               new OpeningCompany
                {
                    일련번호 = 1,
                    개통업체명 = "제이원",
                    개통코드 = "53018644",
                    DB서버 = "118.130.182.139",
                    포트 = "51433",
                    DB명 = "neosecurity_Ring",
                    사용자ID = "neo",
                    비밀번호 = "j101579#"
                }
            };
        }
    }
}
