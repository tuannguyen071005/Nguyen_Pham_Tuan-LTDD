using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace CHKT.Models
{
    // Kế thừa IdentityDbContext thay vì DbContext
    public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

        public DbSet<Device> Devices { get; set; }
        public DbSet<Child> Children { get; set; }
        public DbSet<Rule> Rules { get; set; }
        public DbSet<LocationLog> LocationLogs { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            base.OnModelCreating(builder);

            // Đổi tên schema mặc định thành 'identity' giống database của thầy
            builder.HasDefaultSchema("identity");

            // Nếu muốn đổi tên bảng Device cho chính xác
            builder.Entity<Device>().ToTable("Devices", schema: "identity");
        }
    }
}