using System.Threading.RateLimiting;

namespace H4H_API.Helpers
{
    public class GeocodingRateLimiter
    {
        private readonly RateLimiter _rateLimiter;

        public GeocodingRateLimiter()
        {
            // Nominatim wymaga max 1 request na sekundę
            _rateLimiter = new TokenBucketRateLimiter(new TokenBucketRateLimiterOptions
            {
                TokenLimit = 1,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 10,
                ReplenishmentPeriod = TimeSpan.FromSeconds(1),
                TokensPerPeriod = 1,
                AutoReplenishment = true
            });
        }

        public async Task WaitAsync(CancellationToken cancellationToken = default)
        {
            using var lease = await _rateLimiter.AcquireAsync(1, cancellationToken);
            if (!lease.IsAcquired)
            {
                throw new InvalidOperationException("Rate limit exceeded for geocoding service");
            }
        }

        public ValueTask DisposeAsync()
        {
            return _rateLimiter.DisposeAsync();
        }
    }
}