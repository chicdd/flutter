using Microsoft.EntityFrameworkCore;
using securityindexAPI.Models;

namespace securityindexAPI.Data
{
    public class SecurityRingDBContext : DbContext
    {
        public SecurityRingDBContext(DbContextOptions<SecurityRingDBContext> options)
            : base(options)
        {
        }

        // 뷰를 매핑하기 위한 DbSet
        public DbSet<관제고객마스터> 관제고객마스터뷰 { get; set; }

        // 관제고객 상세 정보를 위한 뷰 매핑 (같은 뷰 사용)

        // 사용자마스터 테이블 매핑
        public DbSet<사용자마스터> 사용자마스터 { get; set; }

        // 관제고객휴일주간 테이블 매핑
        public DbSet<휴일주간> 관제고객휴일주간 { get; set; }

        // 부가서비스 테이블 매핑
        public DbSet<부가서비스마스터> 부가서비스마스터 { get; set; }
        public DbSet<부가서비스코드마스터> 부가서비스코드마스터 { get; set; }
        public DbSet<부가서비스제공마스터> 부가서비스제공마스터 { get; set; }

        // DVR 테이블 매핑
        public DbSet<DVR연동마스터> DVR연동마스터 { get; set; }
        public DbSet<DVR종류코드마스터> DVR종류코드마스터 { get; set; }

        // 스마트폰 인증 테이블 매핑
        public DbSet<스마트정보조회마스터> 스마트정보조회마스터 { get; set; }

        // 문서관리 테이블 매핑
        public DbSet<문서관리마스터> 문서관리마스터 { get; set; }

        // 존코드테이블 매핑
        public DbSet<존마스터> 존마스터 { get; set; }

        // 관제개시마스터 테이블 매핑
        public DbSet<관제개시마스터> 관제개시마스터 { get; set; }

        // 보수점검지시마스터 테이블 매핑
        public DbSet<보수점검지시마스터> 보수점검지시마스터 { get; set; }

        // 코드 테이블들 (드롭다운용)
        public DbSet<관리구역코드모델> 관리구역코드 { get; set; }
        public DbSet<출동권역코드모델> 출동권역코드 { get; set; }
        public DbSet<업종코드모델> 업종대코드 { get; set; }
        public DbSet<경찰서코드모델> 경찰서코드 { get; set; }
        public DbSet<지구대코드모델> 지구대코드 { get; set; }
        public DbSet<사용회선종류모델> 사용회선종류 { get; set; }
        public DbSet<서비스코드모델> 서비스종류코드 { get; set; }
        public DbSet<관제고객상태코드모델> 관제고객상태코드 { get; set; }
        public DbSet<기기종류코드모델> 기기종류코드 { get; set; }
        public DbSet<미경계분류코드모델> 미경계분류코드 { get; set; }
        public DbSet<미경계종류코드모델> 미경계종류코드 { get; set; }
        public DbSet<회사구분코드모델> 회사구분코드 { get; set; }
        public DbSet<지사구분코드모델> 지사구분코드 { get; set; }
        public DbSet<문서종류코드모델> 문서종류코드마스터 { get; set; }
        public DbSet<차량코드모델> 차량코드 { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // 관제고객상세는 관제관리번호를 키로 설정하여 같은 뷰 사용
            modelBuilder.Entity<관제고객마스터>()
                .ToView("관제고객마스터뷰");
            modelBuilder.Entity<관제고객마스터>()
                .HasKey(c => c.관제관리번호);

            // 사용자마스터 테이블 매핑
            modelBuilder.Entity<사용자마스터>()
                .ToTable("사용자마스터")
                .HasKey(u => u.등록번호);

            // 관제고객휴일주간 테이블 매핑
            modelBuilder.Entity<휴일주간>()
                .ToTable("관제고객휴일주간")
                .HasKey(h => h.관제관리번호);


            // 부가서비스 테이블 매핑
            modelBuilder.Entity<부가서비스마스터>()
                .HasKey(b => b.관제관리번호);

            modelBuilder.Entity<부가서비스코드마스터>()
                .HasKey(b => b.부가서비스코드);

            modelBuilder.Entity<부가서비스제공마스터>()
                .HasKey(b => b.부가서비스제공코드);

            // DVR 테이블 매핑
            modelBuilder.Entity<DVR연동마스터>()
                .HasKey(d => d.관제관리번호);

            modelBuilder.Entity<DVR종류코드마스터>()
                .HasKey(d => d.DVR종류코드);

            // 스마트폰 인증 테이블 매핑
            modelBuilder.Entity<스마트정보조회마스터>()
                .HasKey(s => s.휴대폰번호);

            // 문서관리 테이블 매핑
            modelBuilder.Entity<문서관리마스터>()
                .ToTable("문서관리마스터")
                .HasKey(d => d.문서일련번호);

            // 존코드테이블 매핑
            modelBuilder.Entity<존마스터>()
                .ToTable("존코드테이블")
                .HasKey(z => z.존번호);

            // 관제개시마스터 테이블 매핑
            modelBuilder.Entity<관제개시마스터>()
                .ToTable("관제개시마스터")
                .HasKey(g => g.관제관리번호);

            // 보수점검지시마스터 테이블 매핑
            modelBuilder.Entity<보수점검지시마스터>()
                .ToTable("보수점검지시마스터")
                .HasKey(b => b.관제관리번호);

            // 코드 테이블 매핑 (모델의 [Table] 어트리뷰트를 사용하므로 키만 설정)
            modelBuilder.Entity<관리구역코드모델>()
                .HasKey(c => c.관리구역코드);

            modelBuilder.Entity<출동권역코드모델>()
                .HasKey(c => c.출동권역코드);

            modelBuilder.Entity<업종코드모델>()
                .HasKey(c => c.업종대코드);

            modelBuilder.Entity<경찰서코드모델>()
                .HasKey(c => c.경찰서코드);

            modelBuilder.Entity<지구대코드모델>()
                .HasKey(c => c.지구대코드);

            modelBuilder.Entity<사용회선종류모델>()
                .HasKey(c => c.사용회선종류);

            modelBuilder.Entity<서비스코드모델>()
                .HasKey(c => c.서비스종류코드);

            modelBuilder.Entity<기기종류코드모델>()
                .HasKey(c => c.기기종류코드);

            modelBuilder.Entity<미경계분류코드모델>()
                .HasKey(c => c.미경계분류코드);

            modelBuilder.Entity<미경계종류코드모델>()
                .HasKey(c => c.미경계종류코드);

            modelBuilder.Entity<회사구분코드모델>()
                .HasKey(c => c.회사구분코드);

            modelBuilder.Entity<지사구분코드모델>()
                .HasKey(c => c.지사구분코드);

            modelBuilder.Entity<차량코드모델>()
                .HasKey(c => c.차량코드);

            modelBuilder.Entity<문서종류코드모델>()
                .HasKey(c => c.문서종류코드);
        }
    }
}
