using CHKT.Models;
using CHKT.Repositories;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace CHKT.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RulesApiController : ControllerBase
    {
        private readonly IRuleRepository _repo;
        public RulesApiController(IRuleRepository repo) => _repo = repo;

        [HttpGet]
        public async Task<IActionResult> GetAll() => Ok(await _repo.GetAllAsync());

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var rule = await _repo.GetByIdAsync(id);
            return rule == null ? NotFound() : Ok(rule);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Rule rule)
        {
            await _repo.AddAsync(rule);
            return Ok(new { Message = "Thêm quy tắc thành công" });
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Rule rule)
        {
            if (id != rule.Id) return BadRequest();
            await _repo.UpdateAsync(rule);
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