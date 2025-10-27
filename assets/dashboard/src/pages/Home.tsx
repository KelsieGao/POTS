import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { useNavigate } from "react-router-dom";
import { Stethoscope, Heart, Activity } from "lucide-react";

const Home = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto py-12 px-4">
        <div className="text-center space-y-6 mb-16">
          <div className="inline-flex items-center gap-3 mb-4">
            <div className="w-16 h-16 bg-primary rounded-2xl flex items-center justify-center">
              <Activity className="h-9 w-9 text-primary-foreground" />
            </div>
          </div>
          <h1 className="text-5xl font-bold text-foreground">POTS Insight</h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Comprehensive monitoring and management platform for Postural Orthostatic Tachycardia Syndrome
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          <Card className="hover:border-primary transition-all hover:shadow-lg">
            <CardHeader className="text-center space-y-4">
              <div className="mx-auto w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
                <Stethoscope className="h-8 w-8 text-primary" />
              </div>
              <CardTitle className="text-2xl">Clinician Portal</CardTitle>
              <CardDescription className="text-base">
                Access patient data, monitor trends, and manage care plans
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center space-y-4">
              <ul className="text-sm text-muted-foreground space-y-2 text-left">
                <li>• View all patient records</li>
                <li>• Analyze heart rate data and trends</li>
                <li>• Review stand-up test results</li>
                <li>• Track symptom progression</li>
              </ul>
              <Button 
                className="w-full" 
                size="lg"
                onClick={() => navigate("/auth")}
              >
                Clinician Sign In
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:border-primary transition-all hover:shadow-lg">
            <CardHeader className="text-center space-y-4">
              <div className="mx-auto w-16 h-16 bg-accent/10 rounded-full flex items-center justify-center">
                <Heart className="h-8 w-8 text-accent" />
              </div>
              <CardTitle className="text-2xl">Patient Portal</CardTitle>
              <CardDescription className="text-base">
                Track your symptoms, monitor your health, and stay connected
              </CardDescription>
            </CardHeader>
            <CardContent className="text-center space-y-4">
              <ul className="text-sm text-muted-foreground space-y-2 text-left">
                <li>• Log daily symptoms</li>
                <li>• Track heart rate and activity</li>
                <li>• Perform stand-up tests</li>
                <li>• Share data with your care team</li>
              </ul>
              <Button 
                className="w-full" 
                size="lg"
                variant="outline"
                onClick={() => navigate("/patient")}
              >
                Patient Portal
              </Button>
            </CardContent>
          </Card>
        </div>

        <div className="mt-16 text-center">
          <Card className="max-w-2xl mx-auto bg-muted/50">
            <CardHeader>
              <CardTitle>About POTS</CardTitle>
            </CardHeader>
            <CardContent className="text-left space-y-3 text-muted-foreground">
              <p>
                Postural Orthostatic Tachycardia Syndrome (POTS) is a condition characterized by an abnormal increase in heart rate upon standing.
              </p>
              <p>
                This platform helps patients and clinicians work together to monitor symptoms, track progress, and optimize treatment strategies.
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
};

export default Home;
