import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Copy, QrCode, UserPlus } from "lucide-react";
import { toast } from "sonner";

const JoinCodeDialog = () => {
  const { data: profile } = useQuery({
    queryKey: ["clinician-profile"],
    queryFn: async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data, error } = await supabase
        .from("clinician_profiles")
        .select("*")
        .eq("id", user.id)
        .single();

      if (error) throw error;
      return data;
    },
  });

  const copyToClipboard = () => {
    if (profile?.join_code) {
      navigator.clipboard.writeText(profile.join_code);
      toast.success("Join code copied to clipboard!");
    }
  };

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Button variant="outline" size="sm" className="gap-2">
          <UserPlus className="h-4 w-4" />
          Patient Join Code
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Patient Join Code</DialogTitle>
          <DialogDescription>
            Share this code with your patients so they can link their account to your practice
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div className="flex items-center justify-center p-8 bg-muted rounded-lg">
            <div className="text-center">
              <div className="text-4xl font-bold tracking-wider text-primary mb-2">
                {profile?.join_code || "Loading..."}
              </div>
              <p className="text-sm text-muted-foreground">
                6-digit join code
              </p>
            </div>
          </div>
          
          <div className="flex gap-2">
            <Button
              variant="outline"
              className="flex-1"
              onClick={copyToClipboard}
            >
              <Copy className="h-4 w-4 mr-2" />
              Copy Code
            </Button>
            <Button variant="outline" className="flex-1" disabled>
              <QrCode className="h-4 w-4 mr-2" />
              Show QR
            </Button>
          </div>

          <div className="bg-muted/50 p-4 rounded-lg border">
            <p className="text-sm text-muted-foreground">
              <strong>Instructions for patients:</strong>
              <br />
              1. Open the POTS patient app
              <br />
              2. Go to "Link to Clinician"
              <br />
              3. Enter code: <span className="font-mono font-bold">{profile?.join_code}</span>
              <br />
              4. Click "Connect"
            </p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default JoinCodeDialog;
