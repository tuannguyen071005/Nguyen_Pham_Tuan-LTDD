using CHKT.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CHKT.Repositories
{
    public class RuleRepository : IRuleRepository
    {
        private readonly ApplicationDbContext _context;
        public RuleRepository(ApplicationDbContext context) => _context = context;

        public async Task<IEnumerable<Rule>> GetAllAsync() => await _context.Rules.ToListAsync();
        public async Task<Rule> GetByIdAsync(int id) => await _context.Rules.FindAsync(id);
        public async Task AddAsync(Rule rule) { _context.Rules.Add(rule); await _context.SaveChangesAsync(); }
        public async Task UpdateAsync(Rule rule) { _context.Rules.Update(rule); await _context.SaveChangesAsync(); }
        public async Task DeleteAsync(int id)
        {
            var rule = await _context.Rules.FindAsync(id);
            if (rule != null) { _context.Rules.Remove(rule); await _context.SaveChangesAsync(); }
        }
    }
}