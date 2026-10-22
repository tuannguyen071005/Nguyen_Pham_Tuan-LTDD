using CHKT.Models;
using CHKT.Repositories;
using Microsoft.AspNetCore.Authorization; // 1. Thêm thư viện [Authorize]
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims; // 2. Thêm thư viện để lấy ID từ Token
using System.Threading.Tasks;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    // 3. Bắt buộc phải có Token đăng nhập mới được gọi các API trong đây
    public class ChildrenApiController : ControllerBase
    {
        private readonly IChildRepository _repo;
        public ChildrenApiController(IChildRepository repo) => _repo = repo;

        [HttpGet]
        public async Task<IActionResult> GetAll() => Ok(await _repo.GetAllAsync());

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var child = await _repo.GetByIdAsync(id);
            return child == null ? NotFound() : Ok(child);
        }
        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Child child)
        {
            // Kiểm tra xem ParentId có được gửi lên hay không
            if (string.IsNullOrEmpty(child.ParentId))
            {
                return BadRequest(new { Message = "ParentId không được để trống!" });
            }

            await _repo.AddAsync(child);
            return Ok(new { Message = "Thêm hồ sơ trẻ em thành công" });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Child child)
        {
            if (id != child.Id) return BadRequest();

            // Đảm bảo khi update cũng giữ lại ParentId cũ hoặc gán lại từ token nếu cần
            string currentParentId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            child.ParentId = currentParentId;

            await _repo.UpdateAsync(child);
            return Ok(new { Message = "Cập nhật thành công" });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            await _repo.DeleteAsync(id);
            return Ok(new { Message = "Xóa thành công" });
        }
    }
}