<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
        ]);

        User::firstOrCreate(
            ['email' => 'admin@walud.com'],
            [
                'name'           => 'Admin',
                'last_name'      => 'Walud',
                'password'       => Hash::make('Admin@2026!'),
                'tipo_usuario'   => 'admin',
                'document'       => 000000000,
                'tipo_documento' => 'cedula_ciudadania',
                'is_active'      => true,
            ]
        )->assignRole('admin');
    }
}
