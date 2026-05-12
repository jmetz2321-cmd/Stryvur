import Foundation
import Supabase

struct SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://bibfcvkapgonktyfcxow.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpYmZjdmthcGdvbmt0eWZjeG93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxNzY4MjAsImV4cCI6MjA5Mzc1MjgyMH0.yJiWHcZj5LZNfa44NbHqWtAtlvq79kCHUkAuK7nTJCM"
        )
    }
}
