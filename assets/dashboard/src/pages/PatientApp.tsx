import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Heart, Activity, ClipboardList, Smartphone } from "lucide-react";

const PatientApp = () => {
  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto py-8 px-4 space-y-8">
        <div className="text-center space-y-4 mb-12">
          <h1 className="text-4xl font-bold text-foreground">POTS Health Tracker</h1>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Track your symptoms, monitor your heart rate, and manage your POTS condition
          </p>
        </div>

        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          <Card className="hover:border-primary transition-colors cursor-pointer">
            <CardHeader>
              <Heart className="h-8 w-8 text-primary mb-2" />
              <CardTitle>Heart Rate</CardTitle>
              <CardDescription>Monitor your HR trends</CardDescription>
            </CardHeader>
            <CardContent>
              <Button className="w-full" variant="outline">
                View Data
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:border-primary transition-colors cursor-pointer">
            <CardHeader>
              <ClipboardList className="h-8 w-8 text-primary mb-2" />
              <CardTitle>Log Symptoms</CardTitle>
              <CardDescription>Track how you're feeling</CardDescription>
            </CardHeader>
            <CardContent>
              <Button className="w-full" variant="outline">
                Add Entry
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:border-primary transition-colors cursor-pointer">
            <CardHeader>
              <Activity className="h-8 w-8 text-primary mb-2" />
              <CardTitle>Stand-Up Test</CardTitle>
              <CardDescription>Perform POTS assessment</CardDescription>
            </CardHeader>
            <CardContent>
              <Button className="w-full" variant="outline">
                Start Test
              </Button>
            </CardContent>
          </Card>

          <Card className="hover:border-primary transition-colors cursor-pointer">
            <CardHeader>
              <Smartphone className="h-8 w-8 text-primary mb-2" />
              <CardTitle>My Devices</CardTitle>
              <CardDescription>Manage connected devices</CardDescription>
            </CardHeader>
            <CardContent>
              <Button className="w-full" variant="outline">
                View Devices
              </Button>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>Your latest health data and entries</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-center py-12 text-muted-foreground">
              <p>No recent activity</p>
              <p className="text-sm mt-2">Start logging symptoms or connect a device to see your data here</p>
            </div>
          </CardContent>
        </Card>

        <div className="text-center space-y-4 py-8">
          <h2 className="text-2xl font-semibold">Need Help?</h2>
          <p className="text-muted-foreground">
            Contact your healthcare provider or reach out to our support team
          </p>
          <Button variant="outline">Get Support</Button>
        </div>
      </div>
    </div>
  );
};

export default PatientApp;
