namespace H4H_API.Services.Interfaces
{
    public interface IFirebaseStorageService
    {
        Task<string> UploadAvatarAsync(Stream fileStream, string contentType, string fileName, string folderPath);
        Task DeleteFileAsync(string objectName);
    }
}
