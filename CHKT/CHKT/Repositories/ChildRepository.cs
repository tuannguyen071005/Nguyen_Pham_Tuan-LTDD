using CHKT.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace CHKT.Repositories
{
    public class ChildRepository : IChildRepository
    {
        private readonly ApplicationDbContext _context;
        public ChildRepository(ApplicationDbContext context) => _context = context;

        public async Task<IEnumerable<Child>> GetAllAsync() => await _context.Children.ToListAsync();
        public async Task<Child> GetByIdAsync(int id) => await _context.Children.FindAsync(id);
        public async Task AddAsync(Child child) { _context.Children.Add(child); await _context.SaveChangesAsync(); }
        public async Task UpdateAsync(Child child) { _context.Children.Update(child); await _context.SaveChangesAsync(); }
        public async Task DeleteAsync(int id)
        {
            var child = await _context.Children.FindAsync(id);
            if (child != null) { _context.Children.Remove(child); await _context.SaveChangesAsync(); }
        }
    }
}