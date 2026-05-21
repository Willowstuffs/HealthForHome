using Google.Apis.Auth.OAuth2;
using Google.Cloud.Storage.V1;
using H4H_API.Services.Interfaces;

namespace H4H_API.Services.Implementations
{
    public class FirebaseStorageService : IFirebaseStorageService
    {
        private readonly StorageClient _storageClient;
        private readonly string _bucketName;

        public FirebaseStorageService(IConfiguration configuration)
        {
            var credentialsJson = Environment.GetEnvironmentVariable("FIREBASE_CLIENT_CREDENTIALS_JSON");
            if (string.IsNullOrWhiteSpace(credentialsJson))
                throw new InvalidOperationException("FIREBASE_CLIENT_CREDENTIALS_JSON is not configured.");

            _bucketName = Environment.GetEnvironmentVariable("FIREBASE_STORAGE_BUCKET")
                ?? configuration["Firebase:StorageBucket"]
                ?? throw new InvalidOperationException("Firebase storage bucket is not configured. Set FIREBASE_STORAGE_BUCKET or Firebase:StorageBucket.");

            var credential = GoogleCredential.FromJson(credentialsJson);
            _storageClient = StorageClient.Create(credential);
        }

        public async Task<string> UploadAvatarAsync(Stream fileStream, string contentType, string fileName, string folderPath)
        {
            var objectName = $"{folderPath.TrimEnd('/')}/{fileName}";
            var downloadToken = Guid.NewGuid().ToString("N");

            await _storageClient.UploadObjectAsync(
                bucket: _bucketName,
                objectName: objectName,
                contentType: string.IsNullOrWhiteSpace(contentType) ? "application/octet-stream" : contentType,
                source: fileStream);

            var uploadedObject = await _storageClient.GetObjectAsync(_bucketName, objectName);
            uploadedObject.Metadata ??= new Dictionary<string, string>();
            uploadedObject.Metadata["firebaseStorageDownloadTokens"] = downloadToken;
            await _storageClient.UpdateObjectAsync(uploadedObject);

            return $"https://firebasestorage.googleapis.com/v0/b/{_bucketName}/o/{Uri.EscapeDataString(objectName)}?alt=media&token={downloadToken}";
        }

        public async Task DeleteFileAsync(string objectName)
        {
            if (string.IsNullOrWhiteSpace(objectName))
                return;

            await _storageClient.DeleteObjectAsync(_bucketName, objectName);
        }
    }
}
