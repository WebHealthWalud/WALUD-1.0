<?php

namespace App\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

/**
 * Servicio ligero para subir y eliminar archivos en Cloudinary
 * usando su API REST directamente (sin depender del SDK de Composer,
 * que requiere acceso a Packagist). Solo necesita las credenciales
 * en el .env:
 *
 *   CLOUDINARY_CLOUD_NAME=
 *   CLOUDINARY_API_KEY=
 *   CLOUDINARY_API_SECRET=
 */
class CloudinaryService
{
    private string $cloudName;
    private string $apiKey;
    private string $apiSecret;

    public function __construct()
    {
        $this->cloudName = config('services.cloudinary.cloud_name') ?? '';
        $this->apiKey    = config('services.cloudinary.api_key') ?? '';
        $this->apiSecret = config('services.cloudinary.api_secret') ?? '';
    }

    public function isConfigured(): bool
    {
        return $this->cloudName !== '' && $this->apiKey !== '' && $this->apiSecret !== '';
    }

    /**
     * Sube un archivo a Cloudinary.
     *
     * @param UploadedFile $file
     * @param string $folder Carpeta destino dentro de Cloudinary (ej: 'walud/profile_photos')
     * @param string $resourceType 'image' | 'raw' | 'auto'
     * @return array{secure_url:string, public_id:string}
     * @throws Exception
     */
    public function upload(UploadedFile $file, string $folder, string $resourceType = 'auto'): array
    {
        if (!$this->isConfigured()) {
            throw new Exception('Cloudinary no está configurado. Define CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY y CLOUDINARY_API_SECRET en el .env.');
        }

        $timestamp = time();

        // Parámetros que entran en la firma (orden alfabético, sin file/api_key/resource_type/cloud_name)
        $paramsToSign = [
            'folder'    => $folder,
            'timestamp' => $timestamp,
        ];

        $signature = $this->generateSignature($paramsToSign);

        $response = Http::asMultipart()->attach(
            'file',
            fopen($file->getRealPath(), 'r'),
            $file->getClientOriginalName()
        )->post("https://api.cloudinary.com/v1_1/{$this->cloudName}/{$resourceType}/upload", [
            'api_key'   => $this->apiKey,
            'timestamp' => $timestamp,
            'folder'    => $folder,
            'signature' => $signature,
        ]);

        if (!$response->successful()) {
            Log::error('Cloudinary upload failed', ['response' => $response->body()]);
            throw new Exception('Error al subir el archivo a Cloudinary: ' . ($response->json('error.message') ?? 'Error desconocido'));
        }

        $data = $response->json();

        return [
            'secure_url'    => $data['secure_url'],
            'public_id'     => $data['public_id'],
            'resource_type' => $data['resource_type'] ?? $resourceType,
        ];
    }

    /**
     * Elimina un archivo de Cloudinary a partir de su public_id.
     */
    public function destroy(string $publicId, string $resourceType = 'image'): bool
    {
        if (!$this->isConfigured() || empty($publicId)) {
            return false;
        }

        $timestamp = time();
        $paramsToSign = [
            'public_id' => $publicId,
            'timestamp' => $timestamp,
        ];
        $signature = $this->generateSignature($paramsToSign);

        $response = Http::asForm()->post("https://api.cloudinary.com/v1_1/{$this->cloudName}/{$resourceType}/destroy", [
            'public_id' => $publicId,
            'api_key'   => $this->apiKey,
            'timestamp' => $timestamp,
            'signature' => $signature,
        ]);

        if (!$response->successful()) {
            Log::warning('Cloudinary destroy failed', ['response' => $response->body()]);
            return false;
        }

        return ($response->json('result') === 'ok');
    }

    /**
     * Genera la firma SHA1 requerida por Cloudinary para peticiones autenticadas.
     * Ver: https://cloudinary.com/documentation/authentication_signatures
     */
    private function generateSignature(array $params): string
    {
        ksort($params);
        $pairs = [];
        foreach ($params as $key => $value) {
            $pairs[] = "{$key}={$value}";
        }
        $toSign = implode('&', $pairs);

        return sha1($toSign . $this->apiSecret);
    }
}