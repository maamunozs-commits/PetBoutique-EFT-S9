using System.Linq;
using Microsoft.AspNetCore.Mvc;

namespace pipelines_dotnet_core.Controllers
{
    // Catálogo académico: no procesa pagos, pedidos reales ni datos personales.
    [ApiController]
    [Route("api/catalog")]
    public class CatalogController : ControllerBase
    {
        private static readonly Product[] Products = {
            new Product(1, "Alimento para perro 3 kg", 12990),
            new Product(2, "Juguete para gato", 4990),
            new Product(3, "Correa ajustable", 7990)
        };

        [HttpGet]
        public IActionResult Get() => Ok(Products);

        [HttpGet("quote")]
        public IActionResult Quote([FromQuery] int productId, [FromQuery] int quantity)
        {
            if (quantity < 1 || quantity > 10)
                return BadRequest(new { error = "La cantidad debe estar entre 1 y 10." });
            var product = Products.SingleOrDefault(p => p.Id == productId);
            if (product == null) return NotFound(new { error = "Producto inexistente." });
            return Ok(new { productId, quantity, unitPrice = product.PriceClp,
                total = product.PriceClp * quantity, currency = "CLP", simulation = true });
        }

        public record Product(int Id, string Name, int PriceClp);
    }
}
