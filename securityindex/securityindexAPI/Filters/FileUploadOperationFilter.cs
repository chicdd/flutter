using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace securityindexAPI.Filters
{
    public class FileUploadOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            var formFileParameters = context.ApiDescription.ParameterDescriptions
                .Where(p => p.ModelMetadata?.ModelType == typeof(IFormFile))
                .ToList();

            if (formFileParameters.Count == 0)
                return;

            // multipart/form-data로 설정
            operation.RequestBody = new OpenApiRequestBody
            {
                Content = new Dictionary<string, OpenApiMediaType>
                {
                    ["multipart/form-data"] = new OpenApiMediaType
                    {
                        Schema = new OpenApiSchema
                        {
                            Type = "object",
                            Properties = context.ApiDescription.ParameterDescriptions
                                .ToDictionary(
                                    p => p.Name,
                                    p => p.ModelMetadata?.ModelType == typeof(IFormFile)
                                        ? new OpenApiSchema
                                        {
                                            Type = "string",
                                            Format = "binary"
                                        }
                                        : new OpenApiSchema
                                        {
                                            Type = GetSchemaType(p.ModelMetadata?.ModelType)
                                        }
                                ),
                            Required = context.ApiDescription.ParameterDescriptions
                                .Where(p => p.IsRequired)
                                .Select(p => p.Name)
                                .ToHashSet()
                        }
                    }
                }
            };

            // 기존 파라미터 제거
            operation.Parameters.Clear();
        }

        private string GetSchemaType(Type? type)
        {
            if (type == null) return "string";
            if (type == typeof(int) || type == typeof(long)) return "integer";
            if (type == typeof(bool)) return "boolean";
            if (type == typeof(DateTime)) return "string";
            return "string";
        }
    }
}
