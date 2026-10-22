using CHKT.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]
    public class LocationApiController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        public LocationApiController(ApplicationDbContext context) => _context = context;

        [HttpPost]
        public async Task<IActionResult> UpdateLocation([FromBody] LocationLog log)
        {
            log.UpdatedAt = System.DateTime.UtcNow;
            _context.LocationLogs.Add(log);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Cập nhật vị trí thành công" });
        }

        [HttpGet("latest/{deviceId}")]
        public async Task<IActionResult> GetLatestLocation(int deviceId)
        {
            var latest = await _context.LocationLogs
                .Where(x => x.DeviceId == deviceId)
                .OrderByDescending(x => x.UpdatedAt)
                .FirstOrDefaultAsync();

            if (latest == null) return NotFound(new { Message = "Chưa có dữ liệu vị trí" });
            return Ok(latest);
        }
    }
}